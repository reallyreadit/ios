import Foundation
import WebKit
import os.log

private let scripts = [
    ContentScript(
        appSupportFileName: nil,
        bundleFileName: "WebViewMessagingContextAmdModuleShim",
        injectionTime: .atDocumentStart
    ),
    ContentScript(
        appSupportFileName: nil,
        bundleFileName: "WebViewMessagingContext",
        injectionTime: .atDocumentStart
    ),
    ContentScript(
        appSupportFileName: nil,
        bundleFileName: "ContentScriptMessagingShim",
        injectionTime: .atDocumentStart
    ),
    ContentScript(
        appSupportFileName: "ContentScript.js",
        bundleFileName: "ContentScript",
        injectionTime: .atDocumentEnd
    )
]
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
struct ArticleReading {
    static func addContentScript(forConfiguration config: WKWebViewConfiguration) {
        scripts.forEach({
            script in
            var source: String?
            if
                script.appSupportFileName != nil,
                let appSupportDirURL = FileManager.default
                    .urls(
                        for: .applicationSupportDirectory,
                        in: .userDomainMask
                    )
                    .first,
                let fileContent = try? String(
                    contentsOf: appSupportDirURL.appendingPathComponent("reallyreadit/\(script.appSupportFileName!)")
                )
            {
                os_log(.debug, "addContentScript(coder:): loading script from file: %s", script.bundleFileName)
                source = fileContent
            } else if
                let fileContent = try? String(
                    contentsOf: Bundle.main.url(forResource: script.bundleFileName, withExtension: "js")!
                )
            {
                os_log(.debug, "addContentScript(coder:): loading script from bundle: %s", script.bundleFileName)
                source = fileContent
            }
            if source != nil {
                config.userContentController.addUserScript(
                    WKUserScript(
                        source: source!,
                        injectionTime: script.injectionTime,
                        forMainFrameOnly: true
                    )
                )
            } else {
                os_log(.debug, "addContentScript(coder:): error loading script: %s", script.bundleFileName)
            }
        })
    }
    static func fetchArticle(
        url: URL,
        onSuccess: @escaping (_: NSMutableString) -> Void,
        onError: @escaping () -> Void
    ) {
        var request = URLRequest(
            url: URL(
                string: url.absoluteString.replacingOccurrences(
                    of: "^http:",
                    with: "https:",
                    options: [.regularExpression, .caseInsensitive]
                )
            )!
        )
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
                        let stringData = NSMutableString(data: data!, encoding: String.Encoding.utf8.rawValue)
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
