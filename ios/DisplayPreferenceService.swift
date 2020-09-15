import Foundation
import UIKit

struct DisplayPreferenceService {
    static let darkBackgroundColor = UIColor(red: 0.164, green: 0.136, blue: 0.148, alpha: 1.0)
    static let lightBackgroundColor = UIColor(red: 0.968, green: 0.960, blue: 0.957, alpha: 1.0)
    static func resolveDisplayTheme(traits: UITraitCollection, preference: DisplayPreference?) -> DisplayTheme {
        if let preference = preference {
            return preference.theme
        }
        if #available(iOS 12.0, *) {
            if traits.userInterfaceStyle == .dark {
                return DisplayTheme.dark
            }
        }
        return DisplayTheme.light
    }
    static func setBackgroundColor(view: UIView, theme: DisplayTheme) {
        if theme == .light {
            view.backgroundColor = lightBackgroundColor
        } else {
            view.backgroundColor = darkBackgroundColor
        }
    }
    static func setTextColor(label: UILabel, theme: DisplayTheme) {
        if theme == .light {
            label.textColor = .darkText
        } else {
            label.textColor = .lightText
        }
    }
}
