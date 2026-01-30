import Foundation
import AppKit

class AuthService {
    static let shared = AuthService()

    private init() {}

    // Start OAuth flow by opening GitHub authorization page in browser
    func startOAuthFlow() {
        var components = URLComponents(string: GitHubConstants.oauthAuthorizeURL)
        components?.queryItems = [
            URLQueryItem(name: "client_id", value: GitHubConstants.clientID),
            URLQueryItem(name: "redirect_uri", value: GitHubConstants.redirectURI),
            URLQueryItem(name: "scope", value: GitHubConstants.scopes)
        ]

        guard let url = components?.url else {
            print("Failed to construct OAuth URL")
            return
        }

        NSWorkspace.shared.open(url)
    }

    // Handle OAuth callback and exchange code for token
    func handleCallback(url: URL) async throws -> String {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
            throw AuthError.invalidCallback
        }

        return try await exchangeCodeForToken(code: code)
    }

    // Exchange authorization code for access token
    func exchangeCodeForToken(code: String) async throws -> String {
        guard let url = URL(string: GitHubConstants.oauthAccessTokenURL) else {
            throw AuthError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = [
            "client_id": GitHubConstants.clientID,
            "client_secret": GitHubConstants.clientSecret,
            "code": code,
            "redirect_uri": GitHubConstants.redirectURI
        ]

        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw AuthError.httpError(httpResponse.statusCode)
        }

        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)

        guard let accessToken = tokenResponse.accessToken else {
            if let error = tokenResponse.error {
                throw AuthError.oauthError(error)
            }
            throw AuthError.noTokenReceived
        }

        return accessToken
    }

    // Validate token by trying to fetch user info
    func validateToken(_ token: String) async throws -> GitHubUser {
        return try await GitHubAPIClient.shared.request(
            endpoint: GitHubConstants.Endpoints.user,
            token: token
        )
    }
}

// MARK: - Token Response
private struct TokenResponse: Decodable {
    let accessToken: String?
    let tokenType: String?
    let scope: String?
    let error: String?
    let errorDescription: String?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case scope
        case error
        case errorDescription = "error_description"
    }
}

// MARK: - Auth Errors
enum AuthError: LocalizedError {
    case invalidURL
    case invalidResponse
    case invalidCallback
    case httpError(Int)
    case noTokenReceived
    case oauthError(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid authentication URL"
        case .invalidResponse:
            return "Invalid response from GitHub"
        case .invalidCallback:
            return "Invalid OAuth callback - no code received"
        case .httpError(let code):
            return "Authentication failed with HTTP \(code)"
        case .noTokenReceived:
            return "No access token received from GitHub"
        case .oauthError(let error):
            return "OAuth error: \(error)"
        }
    }
}
