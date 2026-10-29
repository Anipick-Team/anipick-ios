import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.feature(
    "MyInfo",
    dependencies: [.client("MyInfo"), .feature("Detail")],
    modules: [.core("MVICore"), .core("Navigation"), .shared("DesignSystem")],
    testModules: [.shared("FeatureTestSupport"), .core("ClientCore")]
)
