import Foundation

protocol WebViewContainerDelegate: class {
    func onStateChange(state: WebViewContainerState) -> Void
}
