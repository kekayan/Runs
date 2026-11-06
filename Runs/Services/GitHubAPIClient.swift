import os
import Foundation

class GitHubAPIClient {
    static let shared = GitHubAPIClient()

    private let baseURL = GitHubConstants.apiBaseURL
    private let session: URLSession

    /// ETag cache: GitHub doesn't count 304 responses against the rate limit.
    private var etagCache: [URL: (etag: String, data: Data, link: String?)] = [:]

    private init() {
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        self.session = URLSession(configuration: config)
    }

    func clearCache() {
        etagCache = [:]
    }

    /// GET a single resource.
    func request<T: Decodable>(endpoint: String, token: String) async throws -> T {
        guard let url = URL(string: baseURL + endpoint) else { throw APIError.invalidURL }
        let (data, _) = try await fetch(url: url, token: token)
        return try decode(T.self, data)
    }

    /// GET every page of a list endpoint, following `Link: rel="next"`.
    func requestAllPages<T: Decodable>(endpoint: String, token: String, maxPages: Int = 20) async throws -> [T] {
        guard var url = URL(string: baseURL + endpoint) else { throw APIError.invalidURL }
        var items: [T] = []
        for _ in 0..<maxPages {
            let (data, link) = try await fetch(url: url, token: token)
            items += try decode([T].self, data)
            guard let next = Self.nextPageURL(from: link) else { break }
            url = next
        }
        return items
    }

    // MARK: - Core

    private func fetch(url: URL, token: String) async throws -> (Data, String?) {
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        if let cached = etagCache[url] {
            request.setValue(cached.etag, forHTTPHeaderField: "If-None-Match")
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError where error.code == .cancelled {
            throw CancellationError()
        } catch {
            throw APIError.networkError(error)
        }

        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        let link = http.value(forHTTPHeaderField: "Link")

        switch http.statusCode {
        case 200...299:
            if let etag = http.value(forHTTPHeaderField: "ETag") {
                etagCache[url] = (etag, data, link)
            }
            return (data, link)
        case 304:
            if let cached = etagCache[url] { return (cached.data, cached.link) }
            throw APIError.invalidResponse
        case 401:
            throw APIError.unauthorized
        case 403, 429:
            if let reset = Self.rateLimitReset(http) {
                Log.api.notice("Rate limited until \(reset)")
                throw APIError.rateLimited(resetAt: reset)
            }
            throw APIError.forbidden
        case 404:
            throw APIError.notFound
        case 422:
            throw APIError.validationFailed
        default:
            throw APIError.httpError(http.statusCode)
        }
    }

    private func decode<T: Decodable>(_ type: T.Type, _ data: Data) throws -> T {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            Log.api.error("Decoding \(String(describing: T.self), privacy: .public) failed: \(error.localizedDescription, privacy: .public)")
            throw APIError.decodingError(error)
        }
    }

    // MARK: - Header parsing

    /// Returns the reset time when the response is a primary or secondary rate-limit error.
    static func rateLimitReset(_ http: HTTPURLResponse) -> Date? {
        if let retryAfter = http.value(forHTTPHeaderField: "Retry-After"), let seconds = Double(retryAfter) {
            return Date().addingTimeInterval(seconds)
        }
        if http.value(forHTTPHeaderField: "X-RateLimit-Remaining") == "0",
           let reset = http.value(forHTTPHeaderField: "X-RateLimit-Reset").flatMap(Double.init) {
            return Date(timeIntervalSince1970: reset)
        }
        return nil
    }

    /// Parses `<https://...>; rel="next", <...>; rel="last"`.
    static func nextPageURL(from link: String?) -> URL? {
        guard let link else { return nil }
        for part in link.split(separator: ",") {
            let pieces = part.split(separator: ";").map { $0.trimmingCharacters(in: .whitespaces) }
            guard pieces.count >= 2, pieces.dropFirst().contains("rel=\"next\"") else { continue }
            let urlString = pieces[0].trimmingCharacters(in: CharacterSet(charactersIn: "<>"))
            return URL(string: urlString)
        }
        return nil
    }
}

// MARK: - API Response Wrappers
struct GitHubAPIListResponse<T: Decodable>: Decodable {
    let workflowRuns: [T]

    enum CodingKeys: String, CodingKey {
        case workflowRuns = "workflow_runs"
    }
}

// MARK: - API Errors
enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case unauthorized
    case forbidden
    case notFound
    case validationFailed
    case rateLimited(resetAt: Date)
    case decodingError(Error)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .invalidResponse: return "Invalid response from server"
        case .httpError(let code): return "HTTP error: \(code)"
        case .unauthorized: return "Your GitHub session expired - please log in again"
        case .forbidden: return "Access forbidden - check your permissions"
        case .notFound: return "Resource not found"
        case .validationFailed: return "Validation failed"
        case .rateLimited(let reset): return "GitHub rate limit reached - resets \(reset.relativeTimeFull())"
        case .decodingError: return "Unexpected response from GitHub"
        case .networkError(let error): return "Network error: \(error.localizedDescription)"
        }
    }
}
