import Foundation

protocol NotificationServiceDelegate: class {
    func onAlertStatusReceived(status: AlertStatus) -> Void
}
