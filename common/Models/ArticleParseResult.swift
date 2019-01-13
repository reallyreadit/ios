import Foundation

struct ArticleParseResult: Codable {
    var title: String
    var source: SourceParseResult
    var datePublished: String?
    var dateModified: String?
    var authors: [AuthorParseResult]
    var section: String?
    var description: String?
    var tags: [String]
    var pageLinks: [PageLinkParseResult]
}
