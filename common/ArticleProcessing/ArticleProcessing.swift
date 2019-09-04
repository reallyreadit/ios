import Foundation
import WebKit

private let viewportMetaTagReplacement = HTMLTagReplacement(
    searchValue: "<meta([^>]*)name=(['\"])viewport\\2([^>]*)>",
    replaceValue: "<meta name=\"viewport\" content=\"width=device-width,initial-scale=1,minimum-scale=1,viewport-fit=cover\">"
)
// this replacement should be called first since the local replacement
// looks at the type to avoid reprocessing and losing the src data
private let remoteScriptDisablingTagReplacement = HTMLTagReplacement(
    searchValue: "<script\\b[^>]*\\bsrc=(['\"])([^'\"]+)\\1[^>]*>[^<]*(?:(?!</script>)<[^<]*)*</script>",
    replaceValue: "<script type=\"text/x-readup-disabled-javascript\" data-src=\"$2\"></script>"
)
private let localScriptDisablingTagReplacement = HTMLTagReplacement(
    searchValue: "<script\\b(?:[^>](?!\\btype=(['\"])(application/(ld\\+)?json|text/x-readup-disabled-javascript)\\1))*>([^<]*(?:(?!</script>)<[^<]*)*)</script>",
    replaceValue: "<script type=\"text/x-readup-disabled-javascript\">$4</script>"
)
private let iframeRemovalTagReplacement = HTMLTagReplacement(
    searchValue: "<iframe\\b[^<]*(?:(?!</iframe>)<[^<]*)*</iframe>",
    replaceValue: ""
)
private let inlineStyleRemovalTagReplacement = HTMLTagReplacement(
    searchValue: "<style\\b[^<]*(?:(?!</style>)<[^<]*)*</style>",
    replaceValue: ""
)
private let linkedStyleRemovalTagReplacement = HTMLTagReplacement(
    searchValue: "<link\\b[^>]*\\brel=(['\"])stylesheet\\1[^>]*>",
    replaceValue: ""
)
private let imageRemovalTagReplacement = HTMLTagReplacement(
    searchValue: "<img\\b[^>]*>",
    replaceValue: ""
)
private let stringEncodings = [
    String.Encoding.utf8,
    String.Encoding.isoLatin1
]
struct ArticleProcessing {
    static func fetchArticle(
        url: URL,
        mode: ArticleProcessingMode,
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
                        let data = data
                    {
                        var stringData: NSMutableString?
                        for var encoding in stringEncodings {
                            stringData = NSMutableString(data: data, encoding: encoding.rawValue)
                            if stringData != nil {
                                break
                            }
                        }
                        if let stringData = stringData {
                            var tagReplacements = [
                                // remote scripts must be disabled first!
                                remoteScriptDisablingTagReplacement,
                                localScriptDisablingTagReplacement,
                                iframeRemovalTagReplacement,
                                inlineStyleRemovalTagReplacement,
                                linkedStyleRemovalTagReplacement
                            ]
                            switch mode {
                            case .reader:
                                tagReplacements += [viewportMetaTagReplacement]
                            case .shareExtension:
                                tagReplacements += [imageRemovalTagReplacement]
                            }
                            tagReplacements.forEach({ replacement in
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
                    } else {
                        onError()
                    }
                }
            )
            .resume()
    }
}
