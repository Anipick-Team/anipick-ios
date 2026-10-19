import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.client(
    "User",
    modules: [.core("ClientCore")],
    liveModules: [.core("Networking"), .core("Storage")],
    hasFixtures: true
)
