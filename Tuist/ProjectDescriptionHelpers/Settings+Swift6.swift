import ProjectDescription

/// 아무 표시가 없는 코드가 속할 액터 (SE-0466, 빌드 설정 "Default Actor Isolation").
/// 모듈 종류별 값은 notes/2026-10-17-R-tma-mvi-program.md Q3를 따른다.
public enum DefaultIsolation: String {
    case mainActor = "MainActor"
    case nonisolated
}

extension Settings {
    /// 새 TMA 모듈 공통 설정: Swift 6 언어 모드 + Approachable Concurrency(SE-0461).
    /// 레거시 앱 타깃(Swift 5 모드)에는 적용하지 않는다.
    public static func swift6(isolation: DefaultIsolation) -> Settings {
        return .settings(
            base: [
                "DEVELOPMENT_TEAM": .string(ProjectEnvironment.teamID),
                "CODE_SIGN_STYLE": "Automatic",
                "SWIFT_VERSION": "6",
                "SWIFT_APPROACHABLE_CONCURRENCY": "YES",
                "SWIFT_DEFAULT_ACTOR_ISOLATION": .string(isolation.rawValue),
            ]
        )
    }
}
