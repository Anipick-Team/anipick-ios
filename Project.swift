import ProjectDescription
import ProjectDescriptionHelpers

let teamID = ProjectEnvironment.teamID
let bundleIDPrefix = ProjectEnvironment.bundleIDPrefix

let project = Project(
    name: "AniPick",
    options: .options(
        automaticSchemesOptions: .enabled(),
        developmentRegion: "en",
        disableSynthesizedResourceAccessors: true
    ),
    settings: .settings(
        base: [
            "DEVELOPMENT_TEAM": .string(teamID),
            "CODE_SIGN_STYLE": "Automatic",
            "SWIFT_VERSION": "5.0",
            "MARKETING_VERSION": "1.2.0",
            "CURRENT_PROJECT_VERSION": "7",
            "ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS": "YES",
            "LOCALIZATION_PREFERS_STRING_CATALOGS": "YES",
            "SWIFT_EMIT_LOC_STRINGS": "YES",
            "ENABLE_USER_SCRIPT_SANDBOXING": "YES",
        ],
        configurations: [
            .debug(name: .debug),
            .release(name: .release),
        ]
    ),
    targets: [
        .target(
            name: "AniPick",
            destinations: [.iPhone],
            product: .app,
            bundleId: "\(bundleIDPrefix).AniPick",
            deploymentTargets: ProjectEnvironment.deploymentTargets,
            infoPlist: .file(path: "AniPick/Info.plist"),
            sources: ["AniPick/**/*.swift"],
            resources: [
                "AniPick/Resourses/**",
                "AniPick/Preview Content/**",
                "AniPick/GoogleService-Info.plist",
            ],
            entitlements: .file(path: "AniPick/AniPick.entitlements"),
            scripts: [
                // Crashlytics dSYM 업로드. 스크립트 샌드박싱이 켜져 있어 읽는 파일을 입력으로 선언한다
                .post(
                    script: "\"${SRCROOT}/Tuist/.build/checkouts/firebase-ios-sdk/Crashlytics/run\"",
                    name: "Upload dSYM to Crashlytics",
                    inputPaths: [
                        "$(SRCROOT)/Tuist/.build/checkouts/firebase-ios-sdk/Crashlytics/run",
                        "$(SRCROOT)/Tuist/.build/checkouts/firebase-ios-sdk/Crashlytics/upload-symbols",
                        "${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}",
                        "${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}/Contents/Resources/DWARF/${PRODUCT_NAME}",
                        "${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}/Contents/Info.plist",
                        "$(TARGET_BUILD_DIR)/$(UNLOCALIZED_RESOURCES_FOLDER_PATH)/GoogleService-Info.plist",
                        "$(TARGET_BUILD_DIR)/$(EXECUTABLE_PATH)",
                    ]
                ),
            ],
            dependencies: [
                .project(target: "Storage", path: .relativeToRoot("Projects/Core/Storage")),
                .project(target: "ClientCore", path: .relativeToRoot("Projects/Core/ClientCore")),
                .project(target: "Networking", path: .relativeToRoot("Projects/Core/Networking")),
                .project(target: "Session", path: .relativeToRoot("Projects/Core/Session")),
                .project(target: "Navigation", path: .relativeToRoot("Projects/Core/Navigation")),
                .project(target: "Analytics", path: .relativeToRoot("Projects/Core/Analytics")),
                .project(target: "DesignSystem", path: .relativeToRoot("Projects/Shared/DesignSystem")),
                .project(target: "Utils", path: .relativeToRoot("Projects/Shared/Utils")),
                .project(target: "SettingInterface", path: .relativeToRoot("Projects/Features/Setting")),
                .project(target: "SettingFeature", path: .relativeToRoot("Projects/Features/Setting")),
                .project(target: "UserClientLive", path: .relativeToRoot("Projects/Clients/UserClient")),
                .project(target: "AuthClientLive", path: .relativeToRoot("Projects/Clients/AuthClient")),
                .project(target: "ReviewInterface", path: .relativeToRoot("Projects/Features/Review")),
                .project(target: "ReviewFeature", path: .relativeToRoot("Projects/Features/Review")),
                .project(target: "ReviewClientLive", path: .relativeToRoot("Projects/Clients/ReviewClient")),
                // Firebase는 AnalyticsLive만 의존한다 (앱이 직접 의존하면 정적 라이브러리가 두 벌 링크된다)
                .project(target: "AnalyticsLive", path: .relativeToRoot("Projects/Core/AnalyticsLive")),
                .external(name: "Alamofire"),
                .external(name: "KakaoSDKAuth"),
                .external(name: "KakaoSDKCommon"),
                .external(name: "KakaoSDKUser"),
                .external(name: "GoogleSignIn"),
                .external(name: "GoogleSignInSwift"),
                .external(name: "PopupView"),
                .external(name: "Kingfisher"),
            ],
            settings: .settings(
                base: [
                    "GENERATE_INFOPLIST_FILE": "YES",
                    "INFOPLIST_KEY_CFBundleDisplayName": "애니픽",
                    "INFOPLIST_KEY_UIApplicationSceneManifest_Generation": "YES",
                    "INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents": "YES",
                    "INFOPLIST_KEY_UILaunchScreen_Generation": "YES",
                    "INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone": "UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight",
                    // 수출 규정: OS 제공 HTTPS 외 자체 암호화 없음 → App Store Connect 업로드 시 암호화 문항 생략
                    "INFOPLIST_KEY_ITSAppUsesNonExemptEncryption": "NO",
                    "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
                    "ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME": "AccentColor",
                    "DEVELOPMENT_ASSET_PATHS": "\"AniPick/Preview Content\"",
                    "ENABLE_PREVIEWS": "YES",
                    "OTHER_LDFLAGS": ["$(inherited)", "-ObjC"],
                    "SUPPORTS_MACCATALYST": "NO",
                    "SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD": "NO",
                    "SUPPORTS_XR_DESIGNED_FOR_IPHONE_IPAD": "NO",
                    // Crashlytics 업로드 스크립트가 Debug 빌드에서도 dSYM을 입력으로 요구한다
                    "DEBUG_INFORMATION_FORMAT": "dwarf-with-dsym",
                ]
            )
        ),
        .target(
            name: "AniPickTests",
            destinations: [.iPhone],
            product: .unitTests,
            bundleId: "\(bundleIDPrefix).AniPickTests",
            deploymentTargets: ProjectEnvironment.deploymentTargets,
            infoPlist: .default,
            sources: ["AniPickTests/**"],
            dependencies: [
                .target(name: "AniPick"),
                .project(target: "Storage", path: .relativeToRoot("Projects/Core/Storage")),
                .project(target: "ClientCore", path: .relativeToRoot("Projects/Core/ClientCore")),
                .project(target: "Session", path: .relativeToRoot("Projects/Core/Session")),
                .project(target: "Navigation", path: .relativeToRoot("Projects/Core/Navigation")),
                .project(target: "MVICore", path: .relativeToRoot("Projects/Core/MVICore")),
                .project(target: "DesignSystem", path: .relativeToRoot("Projects/Shared/DesignSystem")),
                .project(target: "Networking", path: .relativeToRoot("Projects/Core/Networking")),
                .project(target: "SettingInterface", path: .relativeToRoot("Projects/Features/Setting")),
                .project(target: "SettingFeature", path: .relativeToRoot("Projects/Features/Setting")),
                .project(target: "UserClientLive", path: .relativeToRoot("Projects/Clients/UserClient")),
                .project(target: "AuthClientLive", path: .relativeToRoot("Projects/Clients/AuthClient")),
                .project(target: "ReviewInterface", path: .relativeToRoot("Projects/Features/Review")),
                .project(target: "ReviewFeature", path: .relativeToRoot("Projects/Features/Review")),
                .project(target: "ReviewClientLive", path: .relativeToRoot("Projects/Clients/ReviewClient")),
                .project(target: "FeatureTestSupport", path: .relativeToRoot("Projects/Shared/FeatureTestSupport")),
                .external(name: "Alamofire"),
            ]
        ),
        .target(
            name: "AniPickUITests",
            destinations: [.iPhone],
            product: .uiTests,
            bundleId: "\(bundleIDPrefix).AniPickUITests",
            deploymentTargets: ProjectEnvironment.deploymentTargets,
            infoPlist: .default,
            sources: ["AniPickUITests/**"],
            dependencies: [
                .target(name: "AniPick"),
            ]
        ),
    ]
)
