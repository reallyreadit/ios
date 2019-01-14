import Foundation

struct PageParseResult: Codable {
    init(_ data: [String: Any]) {
        url = data["url"] as! String
        number = data["number"] as? Int
        wordCount = data["wordCount"] as! Int
        readableWordCount = data["readableWordCount"] as! Int
        article = ArticleParseResult(data["article"] as! [String: Any])
    }
    let url: String
    let number: Int?
    let wordCount: Int
    let readableWordCount: Int
    let article: ArticleParseResult
    let star = true
}
