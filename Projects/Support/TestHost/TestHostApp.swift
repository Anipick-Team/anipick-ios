import SwiftUI

/// Keychain 등 앱 컨텍스트가 필요한 모듈 테스트의 호스트 앱 (`Project.module(testHost: true)`).
@main
struct TestHostApp: App {
    var body: some Scene {
        WindowGroup {
            EmptyView()
        }
    }
}
