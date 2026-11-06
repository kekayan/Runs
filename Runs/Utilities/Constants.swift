import Foundation

struct GitHubConstants {
    // MARK: - OAuth Configuration
    // Uses the OAuth Device Flow, so no client secret ships with the app.
    // "Enable Device Flow" must be turned on in the OAuth app's settings on GitHub.
    // Override the client ID with the GITHUB_CLIENT_ID environment variable.
    static let clientID = ProcessInfo.processInfo.environment["GITHUB_CLIENT_ID"] ?? "Ov23liiRWGLaXVGnEIN0"

    // OAuth apps have no Actions-only scope; `repo` is the narrowest scope that
    // can read workflow runs of private repositories.
    static let scopes = "repo"

    // MARK: - API URLs
    static let apiBaseURL = "https://api.github.com"
    static let deviceCodeURL = "https://github.com/login/device/code"
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
