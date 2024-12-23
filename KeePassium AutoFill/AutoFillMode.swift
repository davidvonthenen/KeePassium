//  KeePassium Password Manager
//  Copyright © 2018-2024 KeePassium Labs <info@keepassium.com>
//
//  This program is free software: you can redistribute it and/or modify it
//  under the terms of the GNU General Public License version 3 as published
//  by the Free Software Foundation: https://www.gnu.org/licenses/).
//  For commercial licensing, please contact us.

import Foundation

enum AutoFillMode {
    case credentials
    case oneTimeCode
    case text
    case passkey
}

extension AutoFillMode {
    var query: String? {
        switch self {
        case .credentials, .text, .passkey:
            return nil
        case .oneTimeCode:
            return "otp:* "
        }
    }
}

extension AutoFillMode: CustomDebugStringConvertible {
    var debugDescription: String {
        switch self {
        case .credentials:
            return "credentials"
        case .oneTimeCode:
            return "one time code"
        case .passkey:
            return "passkey"
        case .text:
            return "text"
        }
    }
}
