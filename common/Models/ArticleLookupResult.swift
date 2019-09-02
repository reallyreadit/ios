import Foundation

struct ArticleLookupResult: Codable {
    let userArticle: Article
    let userPage: UserPage
    let user: UserAccount
}
