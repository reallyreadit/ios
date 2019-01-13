import Foundation

struct PageParseResult: Codable {
    var url: URL
    var number: Int?
    var wordCount: Int
    var readableWordCount: Int
    var article: ArticleParseResult
}
