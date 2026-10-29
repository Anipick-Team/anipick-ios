import ProjectDescription
import ProjectDescriptionHelpers

// 로그인·로그아웃·가입. 소셜 SDK(Kakao·Google)는 Live만 의존한다 (이관 Q5: App은 SDK를 import하지 않는다)
let project = Project.client(
    "Auth",
    modules: [.core("ClientCore")],
    liveModules: [
        .core("Networking"), .core("Storage"),
        .external("KakaoSDKCommon"), .external("KakaoSDKAuth"), .external("KakaoSDKUser"),
        .external("GoogleSignIn"),
    ],
    // 레거시 로그인 화면이 남아 있는 동안 App도 SDK를 링크한다 — 한 벌만 들어가도록 정적 framework
    liveProduct: .staticFramework
)
