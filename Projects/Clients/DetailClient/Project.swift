import ProjectDescription
import ProjectDescriptionHelpers

// 애니 상세와 상세에서 들어가는 화면들의 요청 (api/animes/{id}/*, 인물·제작사). 화면을 이관하는 대로 늘린다
let project = Project.client(
    "Detail",
    modules: [.core("ClientCore")],
    liveModules: [.core("Networking")]
)
