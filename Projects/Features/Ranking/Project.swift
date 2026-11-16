import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.feature(
    "Ranking",
    dependencies: [
        .client("Ranking"), .client("Metadata"), .feature("Detail"), .feature("Home"),
    ],
    modules: [.core("MVICore"), .core("Navigation"), .shared("DesignSystem")],
    testModules: [.shared("FeatureTestSupport"), .core("ClientCore")]
)
