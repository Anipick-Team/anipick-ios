import ProjectDescription
import ProjectDescriptionHelpers

// 앱 시작 때 받아 둔 장르·연도 목록 (레거시 UserDefaultsManager 메타데이터). 받아 오기는 아직 레거시 AppEntryViewModel
let project = Project.client(
    "Metadata",
    liveModules: [.core("Storage")]
)
