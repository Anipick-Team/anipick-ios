import ProjectDescription

extension Project {
    /// 아직 이관하지 않은 Feature의 **Interface·Testing만** 먼저 만든다 (Strangler).
    ///
    /// 이관한 Feature가 아직 레거시인 화면으로 이동해야 할 때 쓴다. App이 이 Route를 레거시 화면에 연결하고,
    /// 그 Feature를 이관할 때 `.feature(...)`로 바꿔 구현·Tests·Example 타깃을 더한다.
    ///
    /// ```
    /// Projects/Features/<Name>/
    ///   Interface/   <Name>Interface   Route 값 타입, Building 프로토콜
    ///   Testing/     <Name>Testing     가짜 빌더
    /// ```
    public static func featureInterface(_ name: String) -> Project {
        let interface = Target.target(
            name: "\(name)Interface",
            destinations: ProjectEnvironment.destinations,
            product: moduleProduct,
            bundleId: "\(ProjectEnvironment.bundleIDPrefix).\(name)Interface",
            deploymentTargets: ProjectEnvironment.deploymentTargets,
            sources: ["Interface/**"],
            settings: .swift6(isolation: .nonisolated)
        )

        let testing = Target.target(
            name: "\(name)Testing",
            destinations: ProjectEnvironment.destinations,
            product: moduleProduct,
            bundleId: "\(ProjectEnvironment.bundleIDPrefix).\(name)Testing",
            deploymentTargets: ProjectEnvironment.deploymentTargets,
            sources: ["Testing/**"],
            dependencies: [.target(name: interface.name)],
            settings: .swift6(isolation: .nonisolated)
        )

        return Project(
            name: name,
            options: .options(disableSynthesizedResourceAccessors: true),
            targets: [interface, testing]
        )
    }
}
