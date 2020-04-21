import Foundation
import AuthenticationServices

struct WebAuthResponse : Codable {
    init(
        callbackURL: URL?,
        error: String?
    ) {
        self.callbackURL = callbackURL
        self.error = error
    }
    init(
        callbackURL: URL?,
        error: Error?
    ) {
        self.callbackURL = callbackURL
        let errorString: String?
        if let error = error {
            if
                #available(iOS 12.0, *),
                let authError = error as? ASWebAuthenticationSessionError
            {
                switch (authError.code) {
                case .canceledLogin:
                    errorString = "Cancelled"
                case .presentationContextInvalid:
                    errorString = "PresentationContextInvalid"
                case .presentationContextNotProvided:
                    errorString = "PresentationContextNotProvided"
                @unknown default:
                    errorString = "Unknown"
                }
            } else {
                errorString = "Unknown"
            }
        } else {
            errorString = nil
        }
        self.error = errorString
    }
    let callbackURL: URL?
    let error: String?
}
