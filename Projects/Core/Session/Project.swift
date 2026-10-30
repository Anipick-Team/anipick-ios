import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.module(
    "Session",
    layer: .core,
    isolation: .nonisolated,
    dependencies: [.core("Storage"), .core("Networking"), .core("ClientCore")],
    testHost: true
)
