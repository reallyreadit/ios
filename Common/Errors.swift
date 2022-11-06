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

enum AppStoreErrorType: String {
    case
        paymentsDisallowed = "https://docs.readup.org/errors/app-store/payments-disallowed",
        productNotFound = "https://docs.readup.org/errors/app-store/product-not-found",
        purchaseCancelled = "https://docs.readup.org/errors/app-store/purchase-cancelled",
        receiptNotFound = "https://docs.readup.org/errors/app-store/receipt-not-found",
        receiptRequestFailed = "https://docs.readup.org/errors/app-store/receipt-request-failed"
}
enum BrowserExtensionAppErrorType: String {
    case
        messageParsingFailed = "https://docs.readup.org/errors/browser-extension-app/message-parsing-failed",
        readupProtocolFailed = "https://docs.readup.org/errors/browser-extension-app/readup-protocol-failed",
        unexpectedMessageType = "https://docs.readup.org/errors/browser-extension-app/unexpected-message-type"
}
enum GeneralErrorType: String {
    case
        exception = "https://docs.readup.org/errors/general/exception"
}
