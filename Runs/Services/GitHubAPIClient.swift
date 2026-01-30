import Foundation

class GitHubAPIClient {
    static let shared = GitHubAPIClient()

    private let baseURL = GitHubConstants.apiBaseURL
    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        self.session = URLSession(configuration: config)
    }

    // Generic request method
    func request<T: Decodable>(
        endpoint: String,
        method: String = "GET",
        body: Data? = nil,
        token: String? = nil,
        customHeaders: [String: String] = [:]
    ) async throws -> T {
        guard let url = URL(string: baseURL + endpoint) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body

        // Set headers
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")

        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        // Add custom headers
        for (key, value) in customHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        // Check rate limit
        if let remaining = httpResponse.value(forHTTPHeaderField: "X-RateLimit-Remaining"),
           let remainingInt = Int(remaining), remainingInt < 10 {
            print("Warning: GitHub API rate limit low - \(remainingInt) requests remaining")
        }

        // Handle HTTP status codes
        switch httpResponse.statusCode {
        case 200...299:
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                print("Decoding error: \(error)")
                print("Response data: \(String(data: data, encoding: .utf8) ?? "Unable to decode")")
                throw APIError.decodingError(error)
            }
        case 401:
            throw APIError.unauthorized
        case 403:
            throw APIError.forbidden
        case 404:
            throw APIError.notFound
        case 422:
            throw APIError.validationFailed
        default:
            throw APIError.httpError(httpResponse.statusCode)
        }
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
    case decodingError(Error)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .unauthorized:
            return "Unauthorized - Please log in again"
        case .forbidden:
            return "Access forbidden - Check your permissions"
        case .notFound:
            return "Resource not found"
        case .validationFailed:
            return "Validation failed"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}
