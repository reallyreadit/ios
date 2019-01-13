import UIKit
import WebKit

class WebViewContainer: NSObject, WKNavigationDelegate {
    weak var delegate: WebViewContainerDelegate?
    let errorView: UIView = UIView()
    let loadingView: UIView = UIView()
    var state: WebViewContainerState!
    let view = UIView()
    init(webView: WKWebView) {
        super.init()
        // assign self as navigation delegate
        webView.navigationDelegate = self
        // add webview to container
        view.addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        // configure the loading view
        let indicator = UIActivityIndicatorView()
        indicator.color = .gray
        indicator.startAnimating()
        loadingView.addSubview(indicator)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            indicator.centerXAnchor.constraint(equalTo: loadingView.centerXAnchor),
            indicator.centerYAnchor.constraint(equalTo: loadingView.centerYAnchor)
        ])
        // add loading view to container
        loadingView.backgroundColor = .white
        view.addSubview(loadingView)
        loadingView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            loadingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            loadingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            loadingView.topAnchor.constraint(equalTo: view.topAnchor),
            loadingView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        // add error view to container
        errorView.backgroundColor = .white
        view.addSubview(errorView)
        errorView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            errorView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            errorView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            errorView.topAnchor.constraint(equalTo: view.topAnchor),
            errorView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        // set loading state
        setState(.loading)
    }
    func setState(_ state: WebViewContainerState) {
        self.state = state
        switch state {
        case .error:
            loadingView.isHidden = true
            errorView.isHidden = false
        case .loaded:
            loadingView.isHidden = true
            errorView.isHidden = true
        case .loading:
            loadingView.isHidden = false
            errorView.isHidden = true
        }
    }
    func webView(_: WKWebView, didFail: WKNavigation!, withError: Error) {
        setState(.error)
        delegate?.onStateChange(state: .error)
    }
    func webView(_: WKWebView, didFailProvisionalNavigation: WKNavigation!, withError: Error) {
        setState(.error)
        delegate?.onStateChange(state: .error)
    }
    func webView(_: WKWebView, didFinish: WKNavigation!) {
        setState(.loaded)
        delegate?.onStateChange(state: .loaded)
    }
    func webView(_: WKWebView, didStartProvisionalNavigation: WKNavigation!) {
        setState(.loading)
        delegate?.onStateChange(state: .loading)
    }
}
