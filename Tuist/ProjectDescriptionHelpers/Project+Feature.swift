import ProjectDescription

extension Project {
    /// Feature 모듈 1개 = 타깃 5개 (TMA).
    ///
    /// ```
    /// Projects/Features/<Name>/
    ///   Interface/         <Name>Interface   Route 값 타입, Building 프로토콜
    ///   Sources/           <Name>Feature     View, Reducer, Store
    ///   Resources/         (선택)
    ///   Testing/           <Name>Testing     가짜 빌더
    ///   Tests/             <Name>Tests       Store·리듀서 테스트
    ///   Example/Sources/   <Name>Example     단독 실행 데모앱
    /// ```
    ///
    /// 구현 타깃 이름에 `Feature`를 붙이는 이유: 모듈 이름과 같은 이름의 타입이 모듈 안에 있으면
    /// `Module.Type` 형태의 한정 이름 해석이 깨진다.
    ///
    /// - Parameters:
    ///   - dependencies: 다른 Feature·Client의 Interface. 구현 타깃은 표현할 수 없다.
    ///   - modules: Core·Shared 모듈 (Navigation, MVICore, DesignSystem 등)
    ///   - interfaceModules: Interface 타깃이 쓰는 Core·Shared 모듈 (대개 비어 있음)
    public static func feature(
        _ name: String,
        dependencies: [InterfaceDependency] = [],
        modules: [ModuleDependency] = [],
        interfaceModules: [ModuleDependency] = [],
        hasResources: Bool = false
    ) -> Project {
        let interface = Target.target(
            name: "\(name)Interface",
            destinations: ProjectEnvironment.destinations,
            product: moduleProduct,
            bundleId: "\(ProjectEnvironment.bundleIDPrefix).\(name)Interface",
            deploymentTargets: ProjectEnvironment.deploymentTargets,
            sources: ["Interface/**"],
            dependencies: interfaceModules.map(\.target),
            settings: .swift6(isolation: .nonisolated)
        )

        let feature = Target.target(
            name: "\(name)Feature",
            destinations: ProjectEnvironment.destinations,
            product: moduleProduct,
            bundleId: "\(ProjectEnvironment.bundleIDPrefix).\(name)Feature",
            deploymentTargets: ProjectEnvironment.deploymentTargets,
            sources: ["Sources/**"],
            resources: hasResources ? ["Resources/**"] : nil,
            dependencies: [.target(name: interface.name)]
                + dependencies.map(\.interface)
                + modules.map(\.target),
            settings: .swift6(isolation: .mainActor)
        )

        let testing = Target.target(
            name: "\(name)Testing",
            destinations: ProjectEnvironment.destinations,
            product: moduleProduct,
            bundleId: "\(ProjectEnvironment.bundleIDPrefix).\(name)Testing",
            deploymentTargets: ProjectEnvironment.deploymentTargets,
            sources: ["Testing/**"],
            dependencies: [.target(name: interface.name)] + interfaceModules.map(\.target),
            settings: .swift6(isolation: .nonisolated)
        )

        let tests = Target.target(
            name: "\(name)Tests",
            destinations: ProjectEnvironment.destinations,
            product: .unitTests,
            bundleId: "\(ProjectEnvironment.bundleIDPrefix).\(name)Tests",
            deploymentTargets: ProjectEnvironment.deploymentTargets,
            sources: ["Tests/**"],
            dependencies: [.target(name: feature.name), .target(name: testing.name)]
                + dependencies.map(\.testing),
            settings: .swift6(isolation: .mainActor)
        )

        let example = Target.target(
            name: "\(name)Example",
            destinations: ProjectEnvironment.destinations,
            product: .app,
            bundleId: "\(ProjectEnvironment.bundleIDPrefix).\(name)Example",
            deploymentTargets: ProjectEnvironment.deploymentTargets,
            infoPlist: .extendingDefault(with: ["UILaunchScreen": [:]]),
            sources: ["Example/Sources/**"],
            dependencies: [.target(name: feature.name), .target(name: testing.name)]
                + dependencies.map(\.testing),
            settings: .swift6(isolation: .mainActor)
        )

        return Project(
            name: name,
            options: .options(disableSynthesizedResourceAccessors: true),
            targets: [interface, feature, testing, tests, example]
        )
    }
}
