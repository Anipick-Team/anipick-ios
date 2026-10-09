import ProjectDescription

let teamID = "3K4KWAG7KD"
let bundleIDPrefix = "com.moana"

let project = Project(
    name: "AniPick",
    options: .options(
        automaticSchemesOptions: .enabled(),
        developmentRegion: "en",
        disableBundleAccessors: true,
        disableSynthesizedResourceAccessors: true
    ),
    settings: .settings(
        base: [
            "DEVELOPMENT_TEAM": .string(teamID),
            "CODE_SIGN_STYLE": "Automatic",
            "SWIFT_VERSION": "5.0",
            "MARKETING_VERSION": "1.2.0",
            "CURRENT_PROJECT_VERSION": "1",
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
            deploymentTargets: .iOS("16.0"),
            infoPlist: .file(path: "AniPick/Info.plist"),
            sources: ["AniPick/**/*.swift"],
            resources: [
                "AniPick/Resourses/**",
                "AniPick/Preview Content/**",
                "AniPick/GoogleService-Info.plist",
            ],
            entitlements: .file(path: "AniPick/AniPick.entitlements"),
            dependencies: [
                .external(name: "Alamofire"),
                .external(name: "KakaoSDKAuth"),
                .external(name: "KakaoSDKCommon"),
                .external(name: "KakaoSDKUser"),
                .external(name: "GoogleSignIn"),
                .external(name: "GoogleSignInSwift"),
                .external(name: "PopupView"),
                .external(name: "FirebaseAnalytics"),
                .external(name: "FirebaseCrashlytics"),
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
                    "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
                    "ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME": "AccentColor",
                    "DEVELOPMENT_ASSET_PATHS": "\"AniPick/Preview Content\"",
                    "ENABLE_PREVIEWS": "YES",
                    "OTHER_LDFLAGS": ["$(inherited)", "-ObjC"],
                    "SUPPORTS_MACCATALYST": "NO",
                    "SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD": "NO",
                    "SUPPORTS_XR_DESIGNED_FOR_IPHONE_IPAD": "NO",
                ]
            )
        ),
        .target(
            name: "AniPickTests",
            destinations: [.iPhone],
            product: .unitTests,
            bundleId: "\(bundleIDPrefix).AniPickTests",
            deploymentTargets: .iOS("18.2"),
            infoPlist: .default,
            sources: ["AniPickTests/**"],
            dependencies: [
                .target(name: "AniPick"),
            ]
        ),
        .target(
            name: "AniPickUITests",
            destinations: [.iPhone],
            product: .uiTests,
            bundleId: "\(bundleIDPrefix).AniPickUITests",
            deploymentTargets: .iOS("18.2"),
            infoPlist: .default,
            sources: ["AniPickUITests/**"],
            dependencies: [
                .target(name: "AniPick"),
            ]
        ),
    ]
)
