import ProjectDescription

extension Project {
    /// Core·Shared 모듈 = 프레임워크 + 테스트.
    ///
    /// ```
    /// Projects/<Core|Shared>/<Name>/
    ///   Sources/     <Name>
    ///   Resources/   (선택)
    ///   Tests/       <Name>Tests
    /// ```
    ///
    /// - Parameter testHost: 테스트에 호스트 앱이 필요한지. 호스트 없는 테스트 번들은 Keychain에
    ///   접근할 수 없어 `errSecMissingEntitlement`(-34018)로 실패한다 (2026-10-18 Storage 실측).
    /// - Parameter hasTests: 동작 없이 타입만 정의하는 모듈(ClientCore 등)은 `false`
    public static func module(
        _ name: String,
        layer: ModuleLayer,
        isolation: DefaultIsolation,
        dependencies: [ModuleDependency] = [],
        hasResources: Bool = false,
        hasTests: Bool = true,
        testHost: Bool = false
    ) -> Project {
        precondition(
            layer == .core || layer == .shared,
            "Feature는 .feature(...), Client는 .client(...)를 쓴다"
        )

        let framework = Target.target(
            name: name,
            destinations: ProjectEnvironment.destinations,
            product: moduleProduct,
            bundleId: "\(ProjectEnvironment.bundleIDPrefix).\(name)",
            deploymentTargets: ProjectEnvironment.deploymentTargets,
            sources: ["Sources/**"],
            resources: hasResources ? ["Resources/**"] : nil,
            dependencies: dependencies.map(\.target),
            settings: .swift6(isolation: isolation)
        )

        guard hasTests else {
            return Project(
                name: name,
                options: .options(disableSynthesizedResourceAccessors: true),
                targets: [framework]
            )
        }

        let host = testHost ? Target.testHost(for: name) : nil

        // 단위 테스트 타깃이 앱 타깃에 의존하면 Tuist가 TEST_HOST·BUNDLE_LOADER를 설정한다.
        let tests = Target.target(
            name: "\(name)Tests",
            destinations: ProjectEnvironment.destinations,
            product: .unitTests,
            bundleId: "\(ProjectEnvironment.bundleIDPrefix).\(name)Tests",
            deploymentTargets: ProjectEnvironment.deploymentTargets,
            sources: ["Tests/**"],
            dependencies: [.target(name: framework.name)]
                + (host.map { [.target(name: $0.name)] } ?? []),
            settings: .swift6(isolation: isolation)
        )

        return Project(
            name: name,
            options: .options(disableSynthesizedResourceAccessors: true),
            targets: [framework, tests] + (host.map { [$0] } ?? [])
        )
    }
}

extension Target {
    /// 테스트 실행만을 위한 빈 앱. 소스는 모든 모듈이 `Projects/Support/TestHost`를 공유한다.
    static func testHost(for name: String) -> Target {
        return .target(
            name: "\(name)TestHost",
            destinations: ProjectEnvironment.destinations,
            product: .app,
            bundleId: "\(ProjectEnvironment.bundleIDPrefix).\(name)TestHost",
            deploymentTargets: ProjectEnvironment.deploymentTargets,
            infoPlist: .extendingDefault(with: ["UILaunchScreen": [:]]),
            sources: [.glob(.relativeToRoot("Projects/Support/TestHost/**"))],
            settings: .swift6(isolation: .mainActor)
        )
    }
}
