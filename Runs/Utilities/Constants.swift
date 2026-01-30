import Foundation

struct GitHubConstants {
    // MARK: - OAuth Configuration
    // These are app identifiers that identify your OAuth app to GitHub.
    // The Client Secret should be treated as sensitive.
    // You can override these via environment variables if needed.
    
    static let clientID = ProcessInfo.processInfo.environment["GITHUB_CLIENT_ID"] ?? "Ov23liiRWGLaXVGnEIN0"
    static let clientSecret = ProcessInfo.processInfo.environment["GITHUB_CLIENT_SECRET"] ?? "94d4e79d6867dcaf19e9593e65279617af5552d3"
    static let redirectURI = ProcessInfo.processInfo.environment["GITHUB_REDIRECT_URI"] ?? "dev.kekayan.runs://oauth-callback"
    static let scopes = "repo"

    // MARK: - API URLs
    static let apiBaseURL = "https://api.github.com"
    static let oauthAuthorizeURL = "https://github.com/login/oauth/authorize"
    static let oauthAccessTokenURL = "https://github.com/login/oauth/access_token"

    // MARK: - API Endpoints
    struct Endpoints {
        static let user = "/user"
        static let userRepos = "/user/repos"
        static func workflowRuns(owner: String, repo: String) -> String {
            return "/repos/\(owner)/\(repo)/actions/runs"
        }
    }

    // MARK: - Configuration
    static let refreshInterval: TimeInterval = 300 // 5 minutes in seconds
    static let maxRunsToDisplay = 8
    static let reposPerPage = 100
}
