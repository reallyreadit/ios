// Copyright (C) 2022 reallyread.it, inc.
// 
// This file is part of Readup.
// 
// Readup is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License version 3 as published by the Free Software Foundation.
// 
// Readup is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
// 
// You should have received a copy of the GNU Affero General Public License version 3 along with Foobar. If not, see <https://www.gnu.org/licenses/>.

import Foundation
import UIKit
import os.log
import UserNotifications

private func handleAuthorizationRequestResponse(
    granted: Bool,
    error: Error?,
    completionHandler: ((_: Bool) -> Void)?
) {
    os_log("[notifications] auth request result: %d", granted)
    if granted {
        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
        }
    } else {
        APIServerURLSession()
            .postJson(
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
    if let completionHandler = completionHandler {
        completionHandler(granted)
    }
}
class NotificationService: NSObject, UNUserNotificationCenterDelegate {
    static let replyableCategoryId = "replyable"
    static let replyActionId = "reply"
    static func clearAlerts() {
        os_log("[notifications] clearing badge number and notifications")
        UIApplication.shared.applicationIconBadgeNumber = 0
        // setting the badge to 0 removes delivered alerts but it's not specified
        // in the docs so we're explicitly removing them just to be safe
        UNUserNotificationCenter
            .current()
            .removeAllDeliveredNotifications()
    }
    static func requestAuthorization(completionHandler: ((_: Bool) -> Void)? = nil) {
        os_log("[notifications] settings not determined, requesting authorization")
        // .providesAppNotificationSettings only available in iOS >= 12
        if #available(iOS 12.0, *) {
            UNUserNotificationCenter
                .current()
                .requestAuthorization(
                    options: [.alert, .badge, .providesAppNotificationSettings],
                    completionHandler: {
                        granted, error in
                        handleAuthorizationRequestResponse(
                            granted: granted,
                            error: error,
                            completionHandler: completionHandler
                        )
                    }
                )
        } else {
            UNUserNotificationCenter
                .current()
                .requestAuthorization(
                    options: [.alert, .badge],
                    completionHandler: {
                        granted, error in
                        handleAuthorizationRequestResponse(
                            granted: granted,
                            error: error,
                            completionHandler: completionHandler
                        )
                    }
                )
        }
    }
    static func sendToken(_ token: String) {
        os_log("[notifications] sending token")
        if let vendorId = UIDevice.current.identifierForVendor {
            APIServerURLSession()
                .postJson(
                    path: "/Notifications/DeviceRegistration",
                    data: DeviceRegistrationForm(
                        installationId: vendorId.uuidString,
                        name: UIDevice.current.name,
                        token: token
                    ),
                    onSuccess: {
                        (user: UserAccount) in
                        os_log("[notifications] token sent")
                        LocalStorage.setNotificationTokenSent(true)
                        DispatchQueue.main.async {
                            NotificationService.syncBadge(with: user)
                        }
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
    static func syncBadge(with user: UserAccount) {
        os_log("[notifications] syncing badge number to user alerts")
        UIApplication.shared.applicationIconBadgeNumber = (
            (user.aotdAlert ? 1 : 0) +
            user.followerAlertCount +
            user.replyAlertCount
        )
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
        // Only show a banner for local notificatons triggered by the share extension.
        if
            notification.request.trigger == nil,
            #available(iOS 14.0, *)
        {
            completionHandler([.badge, .banner])
        } else {
            completionHandler(.badge)
        }
    }
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        os_log("[notifications] received notification interaction: %s", response.actionIdentifier)
        // don't update the alert status from this method
        // actions that modify the alert status will trigger an additional
        // badge-only notification and we don't want this stale alert state to arrive
        // after that message
        switch response.actionIdentifier {
        case UNNotificationDefaultActionIdentifier:
            if
                let urlString = response.notification.request.content.userInfo["url"] as? String,
                let url = URL(string: urlString)
            {
                os_log("[notifications] viewing notification")
                delegate?.onViewNotification(url: url)
                APIServerURLSession()
                    .postJson(
                        path: "/Notifications/PushView",
                        data: PushViewForm(
                            receiptId: response.notification.request.identifier,
                            url: url.absoluteString
                        ),
                        onSuccess: {
                            DispatchQueue.main.async(execute: completionHandler)
                        },
                        onError: {
                            error in
                            DispatchQueue.main.async(execute: completionHandler)
                        }
                    )
            } else {
                completionHandler()
            }
        case NotificationService.replyActionId:
            if let textResponse = response as? UNTextInputNotificationResponse {
                os_log("[notifications] replying to notification")
                APIServerURLSession()
                    .postJson(
                        path: "/Notifications/PushReply",
                        data: PushReplyForm(
                            receiptId: response.notification.request.identifier,
                            text: textResponse.userText
                        ),
                        onSuccess: {
                            DispatchQueue.main.async(execute: completionHandler)
                        },
                        onError: {
                            error in
                            DispatchQueue.main.async(execute: completionHandler)
                        }
                    )
            } else {
                completionHandler()
            }
        default:
            // don't handle dismiss action
            completionHandler()
            break
        }
    }
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        openSettingsFor notification: UNNotification?
    ) {
        os_log("[notifications] displaying settings")
        delegate?.onViewSettings()
    }
}
