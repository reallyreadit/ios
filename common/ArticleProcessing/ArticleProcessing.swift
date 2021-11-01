import Foundation
import WebKit

private let viewportMetaTagReplacement = HTMLTagReplacement(
    searchValue: "<meta([^>]*)name=(['\"])viewport\\2([^>]*)>",
    replaceValue: "<meta name=\"viewport\" content=\"width=device-width,initial-scale=1,minimum-scale=1,viewport-fit=cover\">"
)
private let scriptRemovalTagReplacement = HTMLTagReplacement(
    searchValue: "<script\\b(?:[^>](?!\\btype=(['\"])application/(ld\\+)?json\\1))*>([^<]*(?:(?!</script>)<[^<]*)*)</script>",
    replaceValue: ""
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
private let sslUrlErrorCodes: [URLError.Code] = [
    .secureConnectionFailed,
    .serverCertificateUntrusted,
    .serverCertificateHasBadDate,
    .serverCertificateNotYetValid,
    .serverCertificateHasUnknownRoot
]
private typealias RequestPreProcessor = (_: inout URLRequest, _: TempHTTPCookieStorage) -> Void
private let hostSpecificRequestPreProcessors: [ String: RequestPreProcessor ] = [
    "npr.org": {
        request, cookieJar in
        cookieJar.storeCookies([
            HTTPCookie(
                properties: [
                    HTTPCookiePropertyKey.domain: request.url!.host!,
                    HTTPCookiePropertyKey.path: "/",
                    HTTPCookiePropertyKey.name: "trackingChoice",
                    HTTPCookiePropertyKey.value: "true"
                ]
            )!,
            HTTPCookie(
                properties: [
                    HTTPCookiePropertyKey.domain: request.url!.host!,
                    HTTPCookiePropertyKey.path: "/",
                    HTTPCookiePropertyKey.name: "choiceVersion",
                    HTTPCookiePropertyKey.value: "1"
                ]
            )!,
            HTTPCookie(
                properties: [
                    HTTPCookiePropertyKey.domain: request.url!.host!,
                    HTTPCookiePropertyKey.path: "/",
                    HTTPCookiePropertyKey.name: "dateOfChoice",
                    HTTPCookiePropertyKey.value: String(
                        Int(
                            Date().timeIntervalSince1970 * 1000
                        )
                    )
                ]
            )!
        ])
    },
    "washingtonpost.com": {
        request, cookieJar in
        cookieJar.storeCookies([
            HTTPCookie(
                properties: [
                    HTTPCookiePropertyKey.domain: request.url!.host!,
                    HTTPCookiePropertyKey.path: "/",
                    HTTPCookiePropertyKey.name: "wp_gdpr",
                    HTTPCookiePropertyKey.value: "1|1"
                ]
            )!
        ])
    },
    "wsj.com": {
        request, cookieJar in
        request.setValue(
            "https://drudgereport.com/",
            forHTTPHeaderField: "Referer"
        )
    }
]
private let browserRequestHeaders = [
    "sec-ch-ua": "\"Chromium\";v=\"94\", \"Google Chrome\";v=\"94\", \";Not A Brand\";v=\"99\"",
    "sec-ch-ua-mobile": "?0",
    "sec-ch-ua-platform": "\"Windows\"",
    "Upgrade-Insecure-Requests": "1",
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/94.0.4606.81 Safari/537.36",
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9",
    "Sec-Fetch-Site": "none",
    "Sec-Fetch-Mode": "navigate",
    "Sec-Fetch-User": "?1",
    "Sec-Fetch-Dest": "document",
    "Accept-Encoding": "gzip, deflate, br",
    "Accept-Language": "en-US,en;q=0.9"
]
private func processArticleContent(
    content: NSMutableString,
    mode: ArticleProcessingMode
) -> NSMutableString {
    var tagReplacements = [
        scriptRemovalTagReplacement,
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
        content.replaceOccurrences(
            of: replacement.searchValue,
            with: replacement.replaceValue,
            options: [.regularExpression, .caseInsensitive],
            range: NSRange(location: 0, length: content.length)
        )
    })
    return content
}
struct ArticleProcessing {
    static func fetchArticle(
        url: URL,
        mode: ArticleProcessingMode,
        onSuccess: @escaping (_: NSMutableString) -> Void,
        onError: @escaping () -> Void
    ) {
        // enforce https
        var request = URLRequest(
            url: (
                URL(
                    string: url.absoluteString.replacingOccurrences(
                        of: "^http:",
                        with: "https:",
                        options: [.regularExpression, .caseInsensitive]
                    )
                )!
            )
        )
        // impersonate chrome on windows 10 desktop
        for header in browserRequestHeaders {
            request.setValue(header.value, forHTTPHeaderField: header.key)
        }
        // use TempHTTPCookieStorage
        let cookieJar = TempHTTPCookieStorage()
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.httpCookieStorage = cookieJar
        // special host handling
        if
            let preProcessor = hostSpecificRequestPreProcessors[
                url.host!.replacingOccurrences(
                    of: "^www\\.",
                    with: "",
                    options: [.regularExpression, .caseInsensitive]
                )
            ]
        {
            preProcessor(&request, cookieJar)
        }
        // initiate request
        URLSession(configuration: sessionConfig)
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
                        for encoding in stringEncodings {
                            stringData = NSMutableString(data: data, encoding: encoding.rawValue)
                            if stringData != nil {
                                break
                            }
                        }
                        if let stringData = stringData {
                            onSuccess(
                                processArticleContent(content: stringData, mode: mode)
                            )
                        } else {
                            onError()
                        }
                    } else {
                        if
                            let urlError = error as? URLError,
                            sslUrlErrorCodes.contains(urlError.code)
                        {
                            APIServerURLSession()
                                .getContent(
                                    path: "/Proxy/Article",
                                    queryItems: URLQueryItem(name: "url", value: url.absoluteString),
                                    onSuccess: {
                                        content in
                                        onSuccess(
                                            processArticleContent(
                                                content: NSMutableString(string: content),
                                                mode: mode
                                            )
                                        )
                                    },
                                    onError: {
                                        _ in
                                        onError()
                                    }
                                )
                        } else {
                            onError()
                        }
                    }
                }
            )
            .resume()
    }
}
