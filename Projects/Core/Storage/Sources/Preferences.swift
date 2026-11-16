import Foundation

/// UserDefaults에 저장하는 설정 값의 키.
/// 레거시 `UserDefaultsManager`와 같은 `name`을 쓰면 공존 기간 동안 같은 값을 공유한다.
public struct PreferenceKey<Value: Sendable>: Sendable {
    public let name: String
    /// 저장된 값이 없거나 타입이 맞지 않을 때 돌려줄 값
    public let defaultValue: Value

    public init(_ name: String, defaultValue: Value) {
        self.name = name
        self.defaultValue = defaultValue
    }
}

/// UserDefaults에 그대로 저장되는 타입 (property list 타입).
public protocol PropertyListValue: Sendable {}

extension String: PropertyListValue {}
extension Bool: PropertyListValue {}
extension Int: PropertyListValue {}
extension Double: PropertyListValue {}
extension Data: PropertyListValue {}
extension Array: PropertyListValue where Element: PropertyListValue {}

/// 민감하지 않은 설정 값 저장소. 토큰 등 민감 정보는 `Keychain`을 쓴다.
public struct Preferences: Sendable {
    // UserDefaults는 SDK에서 Sendable로 표시되지 않았지만 Apple 문서상 thread-safe다.
    // 타입 전체를 @unchecked Sendable로 만드는 대신 이 프로퍼티만 검사에서 제외한다 (SE-0412).
    nonisolated(unsafe) private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func value<Value: PropertyListValue>(for key: PreferenceKey<Value>) -> Value {
        return defaults.object(forKey: key.name) as? Value ?? key.defaultValue
    }

    public func set<Value: PropertyListValue>(_ value: Value, for key: PreferenceKey<Value>) {
        defaults.set(value, forKey: key.name)
    }

    /// JSON으로 인코딩해 `Data`로 저장한 값 (레거시의 장르·분기 메타데이터 방식).
    /// 디코딩에 실패하면 기본값을 돌려준다.
    public func codableValue<Value: Codable>(for key: PreferenceKey<Value>) -> Value {
        guard
            let data = defaults.data(forKey: key.name),
            let value = try? JSONDecoder().decode(Value.self, from: data)
        else {
            return key.defaultValue
        }
        return value
    }

    public func setCodable<Value: Codable>(_ value: Value, for key: PreferenceKey<Value>) throws {
        let data = try JSONEncoder().encode(value)
        defaults.set(data, forKey: key.name)
    }

    public func removeValue<Value>(for key: PreferenceKey<Value>) {
        defaults.removeObject(forKey: key.name)
    }
}
