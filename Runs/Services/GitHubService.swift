import Foundation

class GitHubService {
    static let shared = GitHubService()

    private let apiClient = GitHubAPIClient.shared

    private init() {}

    // Fetch current authenticated user
    func fetchUser(token: String) async throws -> GitHubUser {
        return try await apiClient.request(
            endpoint: GitHubConstants.Endpoints.user,
            token: token
        )
    }

    // Fetch all user repositories
    func fetchRepositories(token: String) async throws -> [Repository] {
        let endpoint = GitHubConstants.Endpoints.userRepos + "?sort=updated&per_page=\(GitHubConstants.reposPerPage)"
        return try await apiClient.request(
            endpoint: endpoint,
            token: token
        )
    }

    // Fetch latest workflow run for a specific repository
    func fetchLatestRun(for repository: Repository, token: String) async throws -> WorkflowRun? {
        let endpoint = GitHubConstants.Endpoints.workflowRuns(
            owner: repository.owner.login,
            repo: repository.name
        ) + "?per_page=1"

        do {
            let response: GitHubAPIListResponse<WorkflowRun> = try await apiClient.request(
                endpoint: endpoint,
                token: token
            )
            return response.workflowRuns.first
        } catch APIError.notFound {
            // Repository might not have any workflow runs
            return nil
        }
    }

    // Fetch latest runs for multiple repositories
    func fetchLatestRunsForRepos(_ repositories: [Repository], token: String) async throws -> [WorkflowRun] {
        // Fetch runs concurrently for all repositories
        try await withThrowingTaskGroup(of: WorkflowRun?.self) { group in
            for repository in repositories {
                group.addTask {
                    try await self.fetchLatestRun(for: repository, token: token)
                }
            }

            var runs: [WorkflowRun] = []
            for try await run in group {
                if let run = run {
                    runs.append(run)
                }
            }

            // Sort by creation date (newest first)
            return runs.sorted { $0.createdAt > $1.createdAt }
        }
    }

    // Fetch latest runs for selected repository IDs
    func fetchLatestRunsForSelectedRepos(
        selectedIDs: Set<Int>,
        allRepos: [Repository],
        token: String
    ) async throws -> [WorkflowRun] {
        let selectedRepos = allRepos.filter { selectedIDs.contains($0.id) }
        return try await fetchLatestRunsForRepos(selectedRepos, token: token)
    }
}
