import Foundation

struct ArticleParseResult: Codable {
    init(_ data: [String: Any]) {
        title = data["title"] as! String
        if let sourceData = data["source"] as? [String: Any] {
            source = SourceParseResult(sourceData)
        } else {
            source = nil
        }
        datePublished = data["datePublished"] as? String
        dateModified = data["dateModified"] as? String
        if
            let authorsData = data["authors"] as? [[String: Any]],
            authorsData.count > 0
        {
            authors = authorsData.map({ data in AuthorParseResult(data) })
        } else {
            authors = [AuthorParseResult]()
        }
        section = data["section"] as? String
        description = data["description"] as? String
        if
            let tagsData = data["tags"] as? [String],
            tagsData.count > 0
        {
            tags = tagsData
        } else {
            tags = [String]()
        }
        if
            let pageLinksData = data["pageLinks"] as? [[String: Any]],
            pageLinksData.count > 0
        {
            pageLinks = pageLinksData.map({ data in PageLinkParseResult(data) })
        } else {
            pageLinks = [PageLinkParseResult]()
        }
        imageUrl = data["imageUrl"] as? String
    }
    let title: String
    let source: SourceParseResult?
    let datePublished: String?
    let dateModified: String?
    let authors: [AuthorParseResult]
    let section: String?
    let description: String?
    let tags: [String]
    let pageLinks: [PageLinkParseResult]
    let imageUrl: String?
}
