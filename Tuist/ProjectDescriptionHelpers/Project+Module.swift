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
    public static func module(
        _ name: String,
        layer: ModuleLayer,
        isolation: DefaultIsolation,
        dependencies: [ModuleDependency] = [],
        hasResources: Bool = false
    ) -> Project {
        precondition(layer == .core || layer == .shared, "Feature는 .feature(...), Client는 .client(...)를 쓴다")

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

        let tests = Target.target(
            name: "\(name)Tests",
            destinations: ProjectEnvironment.destinations,
            product: .unitTests,
            bundleId: "\(ProjectEnvironment.bundleIDPrefix).\(name)Tests",
            deploymentTargets: ProjectEnvironment.deploymentTargets,
            sources: ["Tests/**"],
            dependencies: [.target(name: framework.name)],
            settings: .swift6(isolation: isolation)
        )

        return Project(
            name: name,
            options: .options(disableSynthesizedResourceAccessors: true),
            targets: [framework, tests]
        )
    }
}
