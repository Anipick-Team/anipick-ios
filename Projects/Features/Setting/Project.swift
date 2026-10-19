import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.feature(
    "Setting",
    dependencies: [.client("User")],
    modules: [.core("MVICore"), .core("Navigation"), .shared("DesignSystem")]
)
