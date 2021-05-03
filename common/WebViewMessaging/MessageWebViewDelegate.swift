import Foundation

protocol MessageWebViewDelegate: AnyObject {
    func onMessage(message: (type: String, data: Any?), callbackId: Int?) -> Void
}
