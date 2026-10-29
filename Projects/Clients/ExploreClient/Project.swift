import ProjectDescription
import ProjectDescriptionHelpers

// api/explore-search 등 탐색 요청. 지금은 온보딩(취향 선택) 목록만 — 탐색 화면 이관 때 늘린다
let project = Project.client(
    "Explore",
    modules: [.core("ClientCore")],
    liveModules: [.core("Networking")]
)
