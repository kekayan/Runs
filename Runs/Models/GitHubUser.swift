import Foundation

struct GitHubUser: Codable, Identifiable, Equatable {
    let id: Int
    let login: String
    let avatarUrl: String?
    let name: String?
    let email: String?

    enum CodingKeys: String, CodingKey {
        case id
        case login
        case avatarUrl = "avatar_url"
        case name
        case email
    }
}
