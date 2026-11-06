import Foundation

/// Signs in with GitHub's OAuth Device Flow.
/// No client secret and no redirect URL are involved, so nothing secret ships in the app
/// and there is no callback another app could forge.
class AuthService {
    static let shared = AuthService()

    private init() {}

    struct DeviceCode: Equatable {
        let deviceCode: String
        let userCode: String
        let verificationURL: URL
        let expiresAt: Date
        let interval: TimeInterval
    }

    /// Step 1: ask GitHub for a user code to show and a device code to poll with.
    func requestDeviceCode() async throws -> DeviceCode {
        let response: DeviceCodeResponse = try await post(
            GitHubConstants.deviceCodeURL,
            body: ["client_id": GitHubConstants.clientID, "scope": GitHubConstants.scopes]
        )
        if let error = response.error {
            throw AuthError.oauthError(error, response.errorDescription)
        }
        guard let deviceCode = response.deviceCode,
              let userCode = response.userCode,
              let uri = response.verificationUri,
              let url = URL(string: uri) else {
            throw AuthError.invalidResponse
        }
        return DeviceCode(
            deviceCode: deviceCode,
            userCode: userCode,
            verificationURL: url,
            expiresAt: Date().addingTimeInterval(TimeInterval(response.expiresIn ?? 900)),
            interval: TimeInterval(response.interval ?? 5)
        )
    }

    /// Step 2: poll until the user approves in the browser. Honors cancellation.
    func pollForToken(_ code: DeviceCode) async throws -> String {
        var interval = code.interval
        while Date() < code.expiresAt {
            try await Task.sleep(for: .seconds(interval))

            let response: TokenResponse = try await post(
                GitHubConstants.oauthAccessTokenURL,
                body: [
                    "client_id": GitHubConstants.clientID,
                    "device_code": code.deviceCode,
                    "grant_type": "urn:ietf:params:oauth:grant-type:device_code"
                ]
            )

            if let token = response.accessToken {
                return token
            }
            switch response.error {
            case "authorization_pending":
                continue
            case "slow_down":
                interval = TimeInterval(response.interval ?? Int(interval) + 5)
            case "expired_token":
                throw AuthError.expired
            case "access_denied":
                throw AuthError.denied
            case let error?:
                throw AuthError.oauthError(error, response.errorDescription)
            case nil:
                throw AuthError.noTokenReceived
            }
        }
        throw AuthError.expired
    }

    private func post<T: Decodable>(_ urlString: String, body: [String: String]) async throws -> T {
        guard let url = URL(string: urlString) else { throw AuthError.invalidResponse }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw AuthError.invalidResponse }
        guard http.statusCode == 200 else { throw AuthError.httpError(http.statusCode) }
        return try JSONDecoder().decode(T.self, from: data)
    }
}

// MARK: - Responses
private struct DeviceCodeResponse: Decodable {
    let deviceCode: String?
    let userCode: String?
    let verificationUri: String?
    let expiresIn: Int?
    let interval: Int?
    let error: String?
    let errorDescription: String?

    enum CodingKeys: String, CodingKey {
        case deviceCode = "device_code"
        case userCode = "user_code"
        case verificationUri = "verification_uri"
        case expiresIn = "expires_in"
        case interval
        case error
        case errorDescription = "error_description"
    }
}

private struct TokenResponse: Decodable {
    let accessToken: String?
    let interval: Int?
    let error: String?
    let errorDescription: String?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case interval
        case error
        case errorDescription = "error_description"
    }
}

// MARK: - Auth Errors
enum AuthError: LocalizedError {
    case invalidResponse
    case httpError(Int)
    case noTokenReceived
    case expired
    case denied
    case oauthError(String, String?)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from GitHub"
        case .httpError(let code):
            return "Authentication failed with HTTP \(code)"
        case .noTokenReceived:
            return "No access token received from GitHub"
        case .expired:
            return "The sign-in code expired. Please try again."
        case .denied:
            return "Sign-in was cancelled on GitHub"
        case .oauthError(let error, let description):
            if error == "device_flow_disabled" {
                return "Device Flow is not enabled for this OAuth app on GitHub"
            }
            return description ?? "OAuth error: \(error)"
        }
    }
}
