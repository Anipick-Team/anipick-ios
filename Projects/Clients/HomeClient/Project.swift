import ProjectDescription
import ProjectDescriptionHelpers

// 홈 화면들의 요청 (추천·곧 방영·요일 신작·최근 리뷰·검색). 화면을 이관하는 대로 늘린다
let project = Project.client(
    "Home",
    modules: [.core("ClientCore")],
    liveModules: [.core("Networking")]
)
