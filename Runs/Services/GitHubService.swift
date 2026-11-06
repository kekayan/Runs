import os
import Foundation

class GitHubService {
    static let shared = GitHubService()

    private let apiClient = GitHubAPIClient.shared

    private init() {}

    struct RunsResult {
        var runs: [WorkflowRun]
        var failures: [(repository: Repository, error: Error)]
    }

    func fetchUser(token: String) async throws -> GitHubUser {
        try await apiClient.request(endpoint: GitHubConstants.Endpoints.user, token: token)
    }

    /// All repositories the user can access, across every page.
    func fetchRepositories(token: String) async throws -> [Repository] {
        let endpoint = GitHubConstants.Endpoints.userRepos + "?sort=updated&per_page=\(GitHubConstants.reposPerPage)"
        return try await apiClient.requestAllPages(endpoint: endpoint, token: token)
    }

    func fetchLatestRun(for repository: Repository, token: String) async throws -> WorkflowRun? {
        let endpoint = GitHubConstants.Endpoints.workflowRuns(
            owner: repository.owner.login,
            repo: repository.name
        ) + "?per_page=1"

        do {
            let response: GitHubAPIListResponse<WorkflowRun> = try await apiClient.request(endpoint: endpoint, token: token)
            return response.workflowRuns.first
        } catch APIError.notFound {
            return nil // No Actions, or repo no longer accessible
        }
    }

    /// Fetches each repository independently, so one failing repo doesn't hide the others.
    /// Auth and rate-limit errors affect every repo and are rethrown.
    func fetchLatestRuns(for repositories: [Repository], token: String) async throws -> RunsResult {
        let outcomes = await withTaskGroup(of: (Repository, Result<WorkflowRun?, Error>).self) { group in
            for repository in repositories {
                group.addTask {
                    do {
                        return (repository, .success(try await self.fetchLatestRun(for: repository, token: token)))
                    } catch {
                        return (repository, .failure(error))
                    }
                }
            }
            var outcomes: [(Repository, Result<WorkflowRun?, Error>)] = []
            for await outcome in group { outcomes.append(outcome) }
            return outcomes
        }

        var result = RunsResult(runs: [], failures: [])
        for (repository, outcome) in outcomes {
            switch outcome {
            case .success(let run?):
                result.runs.append(run)
            case .success(nil):
                break
            case .failure(let error):
                switch error {
                case APIError.unauthorized, APIError.rateLimited, is CancellationError:
                    throw error
                default:
                    Log.api.error("Runs for \(repository.fullName, privacy: .public) failed: \(error.localizedDescription, privacy: .public)")
                    result.failures.append((repository, error))
                }
            }
        }
        result.runs.sort { $0.createdAt > $1.createdAt }
        return result
    }
}
