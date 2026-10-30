import ProjectDescription

extension Project {
    /// 도메인별 Client 모듈 (Repository + UseCase를 합친 얇은 계층, 유일한 테스트 경계).
    ///
    /// ```
    /// Projects/Clients/<Name>Client/
    ///   Interface/        <Name>ClientInterface  protocol + 앱 모델 + 에러
    ///   Sources/          <Name>ClientLive       Networking 사용, DTO → 앱 모델 변환
    ///   Testing/          <Name>ClientTesting    시나리오형 Mock
    ///   Tests/            <Name>ClientTests      DTO → 모델 변환 테스트
    ///   Tests/Fixtures/   (선택) 서버 원본 JSON
    /// ```
    ///
    /// - Parameters:
    ///   - modules: Interface가 쓰는 Core 모듈 (대개 `.core("ClientCore")`)
    ///   - liveModules: Live가 추가로 쓰는 모듈 (`.core("Networking")`, 외부 SDK 등)
    ///   - liveProduct: 외부 SDK(정적 라이브러리)를 App도 함께 링크하면 `.staticFramework`로 둔다.
    ///     동적 framework면 SDK가 App과 Live에 한 벌씩 들어가 싱글턴이 둘이 된다 (AnalyticsLive와 같은 이유)
    public static func client(
        _ name: String,
        modules: [ModuleDependency] = [],
        liveModules: [ModuleDependency] = [],
        liveProduct: Product = moduleProduct,
        hasFixtures: Bool = false
    ) -> Project {
        let moduleName = "\(name)Client"

        let interface = Target.target(
            name: "\(moduleName)Interface",
            destinations: ProjectEnvironment.destinations,
            product: moduleProduct,
            bundleId: "\(ProjectEnvironment.bundleIDPrefix).\(moduleName)Interface",
            deploymentTargets: ProjectEnvironment.deploymentTargets,
            sources: ["Interface/**"],
            dependencies: modules.map(\.target),
            settings: .swift6(isolation: .nonisolated)
        )

        let live = Target.target(
            name: "\(moduleName)Live",
            destinations: ProjectEnvironment.destinations,
            product: liveProduct,
            bundleId: "\(ProjectEnvironment.bundleIDPrefix).\(moduleName)Live",
            deploymentTargets: ProjectEnvironment.deploymentTargets,
            sources: ["Sources/**"],
            dependencies: [.target(name: interface.name)]
                + modules.map(\.target)
                + liveModules.map(\.target),
            settings: .swift6(isolation: .nonisolated)
        )

        let testing = Target.target(
            name: "\(moduleName)Testing",
            destinations: ProjectEnvironment.destinations,
            product: moduleProduct,
            bundleId: "\(ProjectEnvironment.bundleIDPrefix).\(moduleName)Testing",
            deploymentTargets: ProjectEnvironment.deploymentTargets,
            sources: ["Testing/**"],
            dependencies: [.target(name: interface.name)] + modules.map(\.target),
            settings: .swift6(isolation: .nonisolated)
        )

        let tests = Target.target(
            name: "\(moduleName)Tests",
            destinations: ProjectEnvironment.destinations,
            product: .unitTests,
            bundleId: "\(ProjectEnvironment.bundleIDPrefix).\(moduleName)Tests",
            deploymentTargets: ProjectEnvironment.deploymentTargets,
            sources: ["Tests/**/*.swift"],
            resources: hasFixtures ? ["Tests/Fixtures/**"] : nil,
            // 테스트는 Interface·Core 모듈도 import한다. 외부 SDK는 Live에 이미 링크되므로 뺀다
            dependencies: [
                .target(name: live.name), .target(name: testing.name),
                .target(name: interface.name),
            ]
                + modules.filter { !$0.isExternal }.map(\.target)
                + liveModules.filter { !$0.isExternal }.map(\.target),
            settings: .swift6(isolation: .nonisolated)
        )

        return Project(
            name: moduleName,
            options: .options(disableSynthesizedResourceAccessors: true),
            targets: [interface, live, testing, tests]
        )
    }
}
