# Readup iOS & macOS Apps
## Description
This repository is an XCode project that contains all the targets required for the Readup iOS and macOS client applications. The macOS application is built from the iOS target using Mac Catalyst. The dependency structure is as follows:
- `Readup` (iOS & macOS)
    - `reader.js` (Copied) The native client reader script generated from the `web` repository.
- `Readup` (iOS-only)
    - `ShareExtension` (Embedded) Enables saving articles to Readup via the iOS share menu.
	     - `share-extension.js` - (Copied) The native client share extension script generated from the `web` repository.
- `Readup` (macOS-only)
    - `AppkitBridge` (Embedded) Enables access to the `AppKit` library.
    - `SafariExtension` (Embedded) The Safari browser extension.
        - Files under `Resources` are identical to those shipped to the Chrome, Firefox, and Edge extension stores after being generated from the `web` repository.
        - `SafariWebExtensionHandler` is the native messaging handler for the Safari extension.
    - `BrowserExtensionApp` (Binary Copied) The command line application that acts as the native messaging handler for the Chrome and Firefox extensions.
## Development Setup Guide
### Configuration
Development and production configuration files are included in the repository as `.plist` files. The debug configuration files assume that you're using the default `*.dev.readup.com` development domain names and `devSessionKey` authentication cookie name in your development environment. Update these values accordingly if needed but do not commit the changes to the repository.

In order to test the browser extension in Chrome and Firefox you will need to set the values for the `ReadupChromeExtensionID` and `ReadupFirefoxExtensionID` key/value pairs in the `IosApp/Debug.plist` configuration file. These temporary extension IDs are unstable and should not be commited to the repository. To retrieve the extension IDs follow the instructions in the `web` repository to build and load the extension in Chrome and Firefox and copy the extension IDs from the browser's extension development interface. Note that for Firefox, you need to use the "Extension ID" value, _not_ the "Internal UUID".

### Development Certificates
See https://github.com/reallyreadit/dev-env for instructions on installing the `ca.dev.reallyread.it.cer` development certificate.

**TODO**: Instructions needed for using a reallyread.it Apple developer account to enable running on macOS.
## Updating Bundled Scripts
This repository includes the production builds of the `nativeClient/reader` and `nativeClient/shareExtension` scripts from the `web` repository. Perform the following update procedure whenever a new version of either script is available:
1. Copy the production build of the latest `nativeClient/reader` or `nativeClient/shareExtension` script to `IosApp/reader.js` or `ShareExtension/share-extension.js` respectively.
2. Update the `ReadupReaderScriptVersion` or `ReadupShareExtensionScriptVersion` values in all `*.plist` files.
## Browser Extension Testing
The browser extension interfaces with the Readup macOS app via a custom `readup://` URL protocol which is invoked using the extension's native messaging handler. Safari uses its own non-standard messaging handler that doesn't require any configuration. Chrome and Firefox both require a native messaging manifest file to be created in order to communicate with the native messaging CLI app.

The Readup macOS app attempts to create these manifest files in the prescribed user home locations on each launch using extension ID values specified in the `IosApp/Debug.plist` configuration file (see above).
- Chrome: https://developer.chrome.com/docs/apps/nativeMessaging/#native-messaging-host
- Firefox: https://developer.mozilla.org/en-US/docs/Mozilla/Add-ons/WebExtensions/Native_manifests#native_messaging_manifests

**Warning**: The production and development apps will create conflicting native messaging manifest files since they both write to the same location and use the same `name`.
## Production Sandbox Testing
### Intro
App Store in-app purchases need to be tested on a physical device using the production Readup servers. Special Apple Sandbox accounts are used to test purchases in production without accruing charges on a real Apple account. Purchases made using a Sandbox account are recorded in the database as `sandbox` transactions and are filtered out of all reporting statistics.

Sandbox subscriptions are accelerated such that a one month subscription lapses in five minutes. Unless a subscription is cancelled it will renew automatically for six cycles. Keep in mind that the regular production renewal grace period may still apply.
### Device Setup (iOS)
The Sandbox account is managed via `Settings` > `App Store` > `SANDBOX ACCOUNT` and does not interfere with the regular Apple account that is signed-in on the device.
As of iOS 15 Apple states the following with respect to Sandbox account testing:
> This account will only be used for testing your in-app purchases while developing locally. Your existing App Store account will be used for TestFlight apps.

However it has been observed that the Sandbox account is in fact used for TestFlight apps. An alternate method of testing involves making the following changes to the `Debug.plist` configuration files using find/replace and running the Readup app on a physical iOS device using XCode:
- Temporarily replace all instances of `dev.readup.com` (or your local development domain suffix) with `readup.com`.
- Temporarily replace all instances of `devSessionKey` (or your development authentication cookie name) with `sessionKey`.

**Note**: Be sure to not commit these changes to the repository and revert all changes after testing is complete.

**Important**: In order to confirm that a purchase is being made using a Sandbox account using either the TestFlight or XCode method:

- Sign out of the Sandbox account via `Settings` before beginning the test. If a Sandbox account is not already signed in, then you should receive a sign-in prompt when attempting the in-app purchase before a confirmation prompt is displayed.
- Look for the following message under `DETAILS` within the iOS subscription confirmation prompt:
  
    > For testing purposes only. You will not be charged for confirming this purchase.
### Test Procedure
It is recommended to clear as much state as possible before beginning the test procedure. That means uninstalling the Readup app, signing out of the Sandbox account, and restarting the iOS Device.

It has been observed that Sandbox accounts can be re-used once the subscription renewals have been completed and the grace period has expired, though for certain tests, such as troubleshooting a failure mode, a new account may be more desirable.

1. Select an Apple Sandbox account, but do not sign in to it on the iOS device under `Settings`. A sign-in prompt will be triggered during the subscription purchase.
    - **Create a new account.**
        1. Sign in to App Store Connect at https://appstoreconnect.apple.com/
        2. Go to "Users and Access."
        3. Select "Testers" under the "Sandbox" section in the left menu.
        4. Create a new Sandbox account using a valid email address (you may want to create an alias at this time).
        5. Complete the account confirmation procedure when you receive the confirmation email from Apple.
        6. Record the Sandbox account in [the log](https://docs.google.com/spreadsheets/d/1_CdZbTgx9kMPSqrrPvHY6laLf6LTsc_97TpwT7oIQN0/).
    - **Use an existing account.**
        1. Select an account from [the log](https://docs.google.com/spreadsheets/d/1_CdZbTgx9kMPSqrrPvHY6laLf6LTsc_97TpwT7oIQN0/).
2. Install the Readup app using TestFlight or XCode as described above under "Device Setup (iOS)."
3. Sign in to Readup using the existing associated Readup account or create a new Readup account if you are using a new Sandbox account.

    If you are using an existing Sandbox account and you create a new Readup account or sign in to Readup using an account other than that which was originally associated with the Sandbox account, you will receive a terminal error stating that the Apple account is associated with another Readup account when you attempt a subscription purchase.
4. Trigger the Readup subscription prompt via the Read screen, My Impact screen, or Settings screen.
6. Sign in to the Apple Sandbox account when prompted. Take your time during this step. There was a bug related to the Readup app being in a background state for an extended period of time while the App Store reviewers must have been signing into their accounts. You should be able to pause here for upwards of a minute or two and still successfully complete the subscription purchase after finishing the sign in.
7. Confirm the purchase using the Apple Sandbox account. It has been observed that you may be asked to sign in and/or confirm the purchase multiple times during the initial subscription purchase.
8. After the purchase has been completed the subscription can be cancelled, upgraded, or downgraded from the Sandbox account management interface at `Settings` > `App Store` > `SANDBOX ACCOUNT`.
