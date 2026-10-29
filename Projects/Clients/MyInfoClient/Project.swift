import ProjectDescription
import ProjectDescriptionHelpers

// api/mypage/* (마이페이지 목록). 프로필·평가한 작품은 해당 화면 이관 때 늘린다
let project = Project.client(
    "MyInfo",
    modules: [.core("ClientCore")],
    liveModules: [.core("Networking")]
)
