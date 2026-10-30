import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.module(
    "Networking",
    layer: .core,
    isolation: .nonisolated,
    dependencies: [.core("ClientCore")]
)
