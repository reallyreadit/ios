import Foundation

protocol MessageWebViewDelegate: class {
    func onMessage(message: (type: String, data: Any?), callbackId: Int?) -> Void
}
