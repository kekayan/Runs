import Foundation

struct Repository: Codable, Identifiable, Equatable {
    let id: Int
    let name: String
    let fullName: String
    let owner: Owner
    let defaultBranch: String?
    let isPrivate: Bool

    struct Owner: Codable, Equatable {
        let login: String
        let id: Int
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case fullName = "full_name"
        case owner
        case defaultBranch = "default_branch"
        case isPrivate = "private"
    }
}
