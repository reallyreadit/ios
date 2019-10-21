import Foundation
import UIKit
import os.log
import UserNotifications

private func handleAuthorizationRequestResponse(
    granted: Bool,
    error: Error?
) {
    os_log("[notifications] auth request result: %d", granted)
    if granted {
        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
        }
    } else {
        APIServer.postJson(
            path: "/Notifications/PushAuthDenial",
            data: PushAuthDenialForm(
                installationId: UIDevice.current.identifierForVendor?.uuidString,
                deviceName: UIDevice.current.name
            ),
            onSuccess: {
                os_log("[notifications] auth request denial sent successfully")
            },
            onError: {
                error in
                os_log(
                    "[notifications] error sending auth request denial: %s",
                    error?.localizedDescription ?? ""
                )
            }
        )
    }
    if let error = error {
        os_log("[notifications] auth request error: %s", error.localizedDescription)
    }
}
class NotificationService: NSObject, UNUserNotificationCenterDelegate {
    static func requestAuthorization() {
        os_log("[notifications] settings not determined, requesting authorization")
        // .providesAppNotificationSettings only available in iOS >= 12
        if #available(iOS 12.0, *) {
            UNUserNotificationCenter
                .current()
                .requestAuthorization(
                    options: [.alert, .badge, .providesAppNotificationSettings],
                    completionHandler: handleAuthorizationRequestResponse
                )
        } else {
            UNUserNotificationCenter
                .current()
                .requestAuthorization(
                    options: [.alert, .badge],
                    completionHandler: handleAuthorizationRequestResponse
                )
        }
    }
    static func sendToken(_ token: String) {
        os_log("[notifications] sending token")
        if let vendorId = UIDevice.current.identifierForVendor {
            APIServer.postJson(
                path: "/Notifications/DeviceRegistration",
                data: DeviceRegistrationForm(
                    installationId: vendorId.uuidString,
                    name: UIDevice.current.name,
                    token: token
                ),
                onSuccess: {
                    os_log("[notifications] token sent")
                    LocalStorage.setNotificationTokenSent(true)
                },
                onError: {
                    error in
                    os_log("[notifications] error sending token: %s", error?.localizedDescription ?? "")
                }
            )
        } else {
            os_log("[notifications] failed to get vendor id")
        }
    }
    weak var delegate: NotificationServiceDelegate?
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        os_log("[notifications] notification received")
        if let serializedAlertStatus = notification.request.content.userInfo["alertStatus"] as? [String: Any] {
            delegate?.onAlertStatusReceived(status: AlertStatus(serialized: serializedAlertStatus))
        }
        if let clearedNotificationIds = notification.request.content.userInfo["clearedNotificationIds"] as? [String] {
            center.removeDeliveredNotifications(withIdentifiers: clearedNotificationIds)
        }
        completionHandler(.badge)
    }
}
