import ProjectDescription
import ProjectDescriptionHelpers

// api/rankings/* (실시간·연도/분기·역대)
let project = Project.client(
    "Ranking",
    modules: [.core("ClientCore")],
    liveModules: [.core("Networking")]
)
