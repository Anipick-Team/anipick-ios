import ProjectDescription
import ProjectDescriptionHelpers

// 리뷰 작성·수정. 최근 리뷰·신고 등은 해당 화면을 이관할 때 늘린다
let project = Project.client(
    "Review",
    modules: [.core("ClientCore")],
    liveModules: [.core("Networking")]
)
