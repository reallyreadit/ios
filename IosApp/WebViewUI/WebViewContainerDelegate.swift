import Foundation

protocol WebViewContainerDelegate: AnyObject {
    func onStateChange(state: WebViewContainerState) -> Void
}
