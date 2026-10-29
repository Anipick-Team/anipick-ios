import ProjectDescription
import ProjectDescriptionHelpers

// 장르·연도·분기·유형 목록 (레거시 UserDefaultsManager 메타데이터). 앱 시작 때 받는 곳은 아직 레거시 AppEntryViewModel
let project = Project.client(
    "Metadata",
    modules: [.core("ClientCore")],
    liveModules: [.core("Storage"), .core("Networking")]
)
