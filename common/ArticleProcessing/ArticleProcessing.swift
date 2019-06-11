import Foundation
import WebKit

private func createTagReplacements(forURL url: URL) -> [HTMLTagReplacement] {
    return [
        HTMLTagReplacement(
            searchValue: "<script\\b(?:[^>](?!\\btype=(['\"])application/ld\\+json\\1))*>[^<]*(?:(?!</script>)<[^<]*)*</script>",
            replaceValue: ""
        ),
        HTMLTagReplacement(
            searchValue: "<iframe\\b[^<]*(?:(?!</iframe>)<[^<]*)*</iframe>",
            replaceValue: ""
        ),
        HTMLTagReplacement(
            searchValue: "<style\\b[^<]*(?:(?!</style>)<[^<]*)*</style>",
            replaceValue: ""
        ),
        HTMLTagReplacement(
            searchValue: "<meta([^>]*)name=(['\"])viewport\\2([^>]*)>",
            replaceValue: "<meta name=\"viewport\" content=\"width=device-width,initial-scale=1,user-scalable=no\">"
        ),
        HTMLTagReplacement(
            searchValue: "<img\\s([^>]*)>",
            replaceValue: "<img data-rrit-base-url='\(url.absoluteString)' $1>"),
        HTMLTagReplacement(
            searchValue: "<img([^>]*)\\ssrc=(['\"])((?:(?!\\2).)*)\\2([^>]*)>",
            replaceValue: "<img$1 data-rrit-src=$2$3$2$4>"
        ),
        HTMLTagReplacement(
            searchValue: "<img([^>]*)\\ssrcset=(['\"])((?:(?!\\2).)*)\\2([^>]*)>",
            replaceValue: "<img$1 data-rrit-srcset=$2$3$2$4>"
        )
    ]
}
struct ArticleProcessing {
    static func fetchArticle(
        url: URL,
        onSuccess: @escaping (_: NSMutableString) -> Void,
        onError: @escaping () -> Void
    ) {
        var request = URLRequest(
            url: (
                SharedBundleInfo.debugReader ?
                    url :
                    URL(
                        string: url.absoluteString.replacingOccurrences(
                            of: "^http:",
                            with: "https:",
                            options: [.regularExpression, .caseInsensitive]
                        )
                    )!
            )
        )
        request.httpShouldHandleCookies = false
        request.setValue(
            "'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.77 Safari/537.36'",
            forHTTPHeaderField: "User-Agent"
        )
        URLSession
            .shared
            .dataTask(
                with: request,
                completionHandler: {
                    (data, response, error) in
                    if
                        error == nil,
                        let httpResponse = response as? HTTPURLResponse,
                        (200...299).contains(httpResponse.statusCode),
                        let data = data,
                        let stringData = NSMutableString(data: data, encoding: String.Encoding.utf8.rawValue)
                    {
                        
                        createTagReplacements(forURL: url).forEach({ replacement in
                            stringData.replaceOccurrences(
                                of: replacement.searchValue,
                                with: replacement.replaceValue,
                                options: [.regularExpression, .caseInsensitive],
                                range: NSRange(location: 0, length: stringData.length)
                            )
                        })
                        onSuccess(stringData)
                    } else {
                        onError()
                    }
                }
            )
            .resume()
    }
}
