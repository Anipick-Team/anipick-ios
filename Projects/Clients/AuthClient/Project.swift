import ProjectDescription
import ProjectDescriptionHelpers

// 로그인·로그아웃. 소셜 SDK(Kakao·Google)는 Auth Feature 이관 때 Live에 추가한다 (이관 Q5)
let project = Project.client(
    "Auth",
    modules: [.core("ClientCore")],
    liveModules: [.core("Networking")]
)
