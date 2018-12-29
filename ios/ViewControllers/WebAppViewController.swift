import UIKit
import WebKit
import os.log

class WebAppViewController: UIViewController, WKScriptMessageHandler {
    var webView: WKWebView!
    override func loadView() {
        let config = WKWebViewConfiguration()
        config.userContentController = WKUserContentController()
        config.userContentController.add(self, name: "reallyreadit")
        webView = WKWebView(
            frame: .zero,
            configuration: config
        )
        webView.customUserAgent = "reallyread.it iOS App WebView"
        view = webView
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController!.setNavigationBarHidden(true, animated: false)
        navigationController!.hidesBarsOnSwipe = true
        webView.load(
            URLRequest(
                url: URL(string: "http://dev.reallyread.it")!
            )
        )
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if
            let destination = segue.destination as? ArticleViewController,
            let data = sender as? [String: Any]
        {
            destination.params = ArticleViewControllerParams(
                article: ArticleViewControllerArticleParam(
                    title: data["title"] as! String,
                    url: URL(string: data["url"] as! String)!
                )/*,
                onRegisterPage: {
                    data in
                    os_log(.debug, "onRegisterPage")
                    return ""
                },
                onCommitReadState: {
                    commitData, isCompletionCommit in
                    os_log(.debug, "onCommitReadState")
                    return ""
                }*/
            )
        }
    }
    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        if
            let envelope = message.body as? [String: Any],
            let message = envelope["data"] as? [String: Any]
        {
            if let messageType = message["type"] as? String {
                switch messageType {
                case "readArticle":
                    performSegue(
                        withIdentifier: "readArticle",
                        sender: message["data"]
                    )
                default:
                    return
                }
            }
        }
    }
}
