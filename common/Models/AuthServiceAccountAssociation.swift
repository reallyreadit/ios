import Foundation

struct AuthServiceAccountAssociation: Codable {
    let dateAssociated: Date
    let emailAddress: String
    let handle: String?
    let identityId: Int
    let provider: AuthServiceProvider
}
