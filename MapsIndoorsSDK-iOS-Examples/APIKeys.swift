import Foundation

struct APIKeys {
    
    private static let keys: [String: Any]? = {
        if let path = Bundle.main.path(forResource: "APIKeys", ofType: "plist"),
           let dict = NSDictionary(contentsOfFile: path) as? [String: Any] {
            return dict
        }
        return nil
    }()
    
    static let googleMapsAPIKey: String = {
        return keys?["GoogleMapsAPIKey"] as? String ?? "[YOUR_API_KEY]"
    }()
    
    static let mapboxAPIKey: String = {
        return keys?["MapboxAPIKey"] as? String ?? "[YOUR_API_KEY]"
    }()
}
