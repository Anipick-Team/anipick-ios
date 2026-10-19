import Foundation

private final class DesignSystemBundleToken {}

extension Bundle {
    /// DesignSystem의 리소스 번들. 이름 문자열로 에셋을 찾는 레거시 코드가 쓴다.
    /// ```swift
    /// Image("cloud-image", bundle: .designSystem)
    /// ```
    nonisolated public static let designSystem = Bundle(for: DesignSystemBundleToken.self)
}
