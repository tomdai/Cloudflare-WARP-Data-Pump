import Foundation

struct iCloudKeyValueStorage {
    enum Key: String {
        case clientConfigurationID
    }
    
    private static func validate(value: Any, for key: Self.Key) {
        switch key {
        case .clientConfigurationID:
            guard type(of: value) == String.self else { fatalError() }
        }
    }
    
    static func set(key: Self.Key, value: Any) {
        Self.validate(value: value, for: key)
        NSUbiquitousKeyValueStore.default.set(value, forKey: key.rawValue)
    }
    
    static func string(for key: Self.Key) -> String? {
        NSUbiquitousKeyValueStore.default.string(forKey: key.rawValue)
    }
}
