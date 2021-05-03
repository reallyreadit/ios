import Foundation

protocol NotificationServiceDelegate: AnyObject {
    func onAlertStatusReceived(status: AlertStatus) -> Void
    func onViewNotification(url: URL) -> Void
    func onViewSettings() -> Void
}
