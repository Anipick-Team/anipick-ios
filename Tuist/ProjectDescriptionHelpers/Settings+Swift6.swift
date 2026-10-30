import ProjectDescription

/// 아무 표시가 없는 코드가 속할 액터 (SE-0466, 빌드 설정 "Default Actor Isolation").
/// 모듈 종류별 값은 notes/2026-10-17-R-tma-mvi-program.md Q3를 따른다.
public enum DefaultIsolation: String {
    case mainActor = "MainActor"
    case nonisolated
}

extension Settings {
    /// 새 TMA 모듈 공통 설정: Swift 6 언어 모드 + Approachable Concurrency(SE-0461).
    /// 앱 타깃은 프로젝트 설정에 같은 값(MainActor)을 직접 둔다 (`Project.swift`).
    /// - Parameter extra: 모듈마다 덧붙이는 설정 (예: DesignSystem의 에셋 심볼 자동 생성 끄기)
    public static func swift6(
        isolation: DefaultIsolation,
        extra: SettingsDictionary = [:]
    ) -> Settings {
        let base: SettingsDictionary = [
            "DEVELOPMENT_TEAM": .string(ProjectEnvironment.teamID),
            "CODE_SIGN_STYLE": "Automatic",
            "SWIFT_VERSION": "6",
            "SWIFT_APPROACHABLE_CONCURRENCY": "YES",
            "SWIFT_DEFAULT_ACTOR_ISOLATION": .string(isolation.rawValue),
        ]
        return .settings(base: base.merging(extra) { _, extra in extra })
    }
}
