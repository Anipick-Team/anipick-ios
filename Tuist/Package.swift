// swift-tools-version: 5.9
import PackageDescription

#if TUIST
    import struct ProjectDescription.PackageSettings

    let packageSettings = PackageSettings(
        productTypes: [:]
    )
#endif

let package = Package(
    name: "AniPick",
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire", from: "5.10.2"),
        .package(url: "https://github.com/kakao/kakao-ios-sdk", from: "2.24.2"),
        .package(url: "https://github.com/google/GoogleSignIn-iOS", from: "8.0.0"),
        .package(url: "https://github.com/exyte/PopupView.git", from: "4.1.15"),
        .package(url: "https://github.com/firebase/firebase-ios-sdk", from: "12.10.0"),
        .package(url: "https://github.com/onevcat/Kingfisher.git", from: "8.8.0"),
    ]
)
