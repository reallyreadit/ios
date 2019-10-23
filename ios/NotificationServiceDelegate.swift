import Foundation

protocol NotificationServiceDelegate: class {
    func onAlertStatusReceived(status: AlertStatus) -> Void
    func onViewNotification(url: URL) -> Void
    func onViewSettings() -> Void
}
