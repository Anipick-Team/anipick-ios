import ProjectDescription

// 레거시 앱(루트 Project.swift)과 TMA 모듈(Projects/**)을 한 워크스페이스로 묶는다.
let workspace = Workspace(
    name: "AniPick",
    projects: [
        ".",
        "Projects/**",
    ]
)
