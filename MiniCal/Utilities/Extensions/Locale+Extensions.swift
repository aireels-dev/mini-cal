import Foundation

extension Locale {
    var languageCodeIdentifier: String {
        if #available(macOS 13.0, *) {
            return language.languageCode?.identifier ?? ""
        }
        return languageCode ?? ""
    }

    var scriptCodeIdentifier: String? {
        if #available(macOS 13.0, *) {
            return language.script?.identifier
        }
        return scriptCode
    }

    var regionCodeIdentifier: String {
        if #available(macOS 13.0, *) {
            return region?.identifier ?? ""
        }
        return regionCode ?? ""
    }
}
