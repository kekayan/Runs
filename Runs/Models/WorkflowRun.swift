import Foundation
import SwiftUI

struct WorkflowRun: Codable, Identifiable, Equatable {
    let id: Int
    let name: String?
    let headSha: String
    let status: Status
    let conclusion: Conclusion?
    let createdAt: Date
    let htmlUrl: String
    let repository: RepositoryInfo

    struct RepositoryInfo: Codable, Equatable {
        let name: String
        let fullName: String

        enum CodingKeys: String, CodingKey {
            case name
            case fullName = "full_name"
        }
    }

    enum Status: String, Codable {
        case queued
        case inProgress = "in_progress"
        case completed
        case waiting
        case requested
        case pending

        var displayName: String {
            switch self {
            case .queued: return "Queued"
            case .inProgress: return "In Progress"
            case .completed: return "Completed"
            case .waiting: return "Waiting"
            case .requested: return "Requested"
            case .pending: return "Pending"
            }
        }
    }

    enum Conclusion: String, Codable {
        case success
        case failure
        case cancelled
        case skipped
        case neutral
        case timedOut = "timed_out"
        case actionRequired = "action_required"

        var color: Color {
            switch self {
            case .success: return .green
            case .failure: return .red
            case .cancelled: return .gray
            case .skipped: return .gray
            case .neutral: return .blue
            case .timedOut: return .orange
            case .actionRequired: return .yellow
            }
        }

        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .failure: return "xmark.circle.fill"
            case .cancelled: return "stop.circle.fill"
            case .skipped: return "arrow.forward.circle.fill"
            case .neutral: return "minus.circle.fill"
            case .timedOut: return "clock.fill"
            case .actionRequired: return "exclamationmark.circle.fill"
            }
        }
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case headSha = "head_sha"
        case status
        case conclusion
        case createdAt = "created_at"
        case htmlUrl = "html_url"
        case repository
    }

    // Computed properties
    var shortCommitSha: String {
        String(headSha.prefix(5))
    }

    var displayStatus: String {
        if status == .completed, let conclusion = conclusion {
            return conclusion.rawValue.capitalized
        }
        return status.displayName
    }

    var statusColor: Color {
        if status == .completed, let conclusion = conclusion {
            return conclusion.color
        }
        // For non-completed statuses
        switch status {
        case .inProgress, .queued, .waiting, .requested, .pending:
            return .yellow
        case .completed:
            return .gray
        }
    }

    var statusIcon: String {
        if status == .completed, let conclusion = conclusion {
            return conclusion.icon
        }
        // For non-completed statuses
        switch status {
        case .inProgress:
            return "arrow.triangle.2.circlepath"
        case .queued, .waiting, .requested, .pending:
            return "clock.fill"
        case .completed:
            return "circle.fill"
        }
    }
}
