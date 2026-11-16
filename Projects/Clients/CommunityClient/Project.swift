import ProjectDescription
import ProjectDescriptionHelpers

// api/community/* (커뮤니티 게시판·글·댓글). 탐색 Feature(커뮤니티 포함, 이관 Q6)가 쓴다. 화면을 이관하는 대로 늘린다
let project = Project.client(
    "Community",
    modules: [.core("ClientCore")],
    liveModules: [.core("Networking")]
)
