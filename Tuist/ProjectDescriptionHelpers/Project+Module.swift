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
    /// - Parameter product: 기본은 `moduleProduct`(동적). 외부 SDK를 감싸는 모듈은 `.staticFramework` —
    ///   동적 framework가 정적 SDK를 품으면 앱이 쓰는 다른 SDK와 공유하는 정적 라이브러리
    ///   (GoogleUtilities 등)가 앱과 framework에 한 벌씩 링크된다 (2026-10-19 AnalyticsLive).
    public static func module(
        _ name: String,
        layer: ModuleLayer,
        isolation: DefaultIsolation,
        dependencies: [ModuleDependency] = [],
        hasResources: Bool = false,
        hasTests: Bool = true,
        testHost: Bool = false,
        product: Product = moduleProduct
    ) -> Project {
        precondition(
            layer == .core || layer == .shared,
            "Feature는 .feature(...), Client는 .client(...)를 쓴다"
        )

        let framework = Target.target(
            name: name,
            destinations: ProjectEnvironment.destinations,
            product: product,
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
        // 테스트는 모듈의 공개 API에 드러나는 의존 모듈(예: ClientCore의 TransportError)도 import하므로
        // 같은 의존을 선언한다 (선언하지 않으면 tuist inspect dependencies가 암시적 의존으로 잡는다).
        // 외부 SDK는 뺀다 — 정적 라이브러리라 테스트 번들에 한 벌 더 링크된다 (2026-10-19 Analytics).
        let tests = Target.target(
            name: "\(name)Tests",
            destinations: ProjectEnvironment.destinations,
            product: .unitTests,
            bundleId: "\(ProjectEnvironment.bundleIDPrefix).\(name)Tests",
            deploymentTargets: ProjectEnvironment.deploymentTargets,
            sources: ["Tests/**"],
            dependencies: [.target(name: framework.name)]
                + dependencies.filter { !$0.isExternal }.map(\.target)
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
