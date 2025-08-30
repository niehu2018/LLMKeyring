import Foundation

class LocalizationHelper: ObservableObject {
    static let shared = LocalizationHelper()
    
    @Published var currentLanguage: String = UserDefaults.standard.string(forKey: "appLanguage") ?? "system" {
        didSet {
            UserDefaults.standard.set(currentLanguage, forKey: "appLanguage")
        }
    }
    
    private var bundle: Bundle {
        let language = effectiveLanguage
        
        guard let path = Bundle.main.path(forResource: language, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return Bundle.main
        }
        
        return bundle
    }
    
    private var effectiveLanguage: String {
        switch currentLanguage {
        case "en": return "en"
        case "zh-Hans": return "zh-Hans"
        case "system":
            let systemLang: String
            if #available(macOS 13.0, *) {
                systemLang = Locale.current.language.languageCode?.identifier ?? "en"
            } else {
                systemLang = Locale.current.languageCode ?? "en"
            }
            if systemLang.hasPrefix("zh") {
                return "zh-Hans"
            } else {
                return "en"
            }
        default: return "en"
        }
    }
    
    func localizedString(for key: String, comment: String = "") -> String {
        return NSLocalizedString(key, bundle: bundle, comment: comment)
    }
}

// SwiftUI helper function
func LocalizedString(_ key: String, comment: String = "") -> String {
    LocalizationHelper.shared.localizedString(for: key, comment: comment)
}