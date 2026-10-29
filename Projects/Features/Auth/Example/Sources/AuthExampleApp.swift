import AuthClientInterface
import AuthClientTesting
import AuthFeature
import AuthInterface
import FeatureTestSupport
import SwiftUI

/// 서버 없이 이메일 로그인을 시나리오별로 띄운다.
@main
struct AuthExampleApp: App {
    var body: some Scene {
        WindowGroup {
            ExampleRoot()
        }
    }
}

struct ExampleRoot: View {
    @State private var navigator = ExampleNavigator()
    @State private var builder: AuthBuilder?
    @State private var loggedIn = false

    private static let scenarios: [(String, EmailLoginResult)] = [
        (
            "성공",
            .success(
                LoggedInUser(
                    userId: 1, nickname: "애니픽", hasAccessToken: true, reviewCompleted: true))
        ),
        ("비밀번호 형식 (110)", .invalidPasswordFormat),
        ("이메일·비밀번호 확인 (104)", .wrongCredentials),
        ("가입 안 된 계정 (112)", .accountNotFound),
        ("탈퇴한 계정 (132)", .withdrawn),
    ]

    var body: some View {
        NavigationStack(path: $navigator.path) {
            List {
                Section("이메일 로그인") {
                    ForEach(Self.scenarios, id: \.0) { title, result in
                        Button(title) {
                            open(.emailLogin, result: result)
                        }
                    }
                }
                Section("회원가입") {
                    Button("성공 → 취향 선택(가짜)") {
                        open(.emailSignup, result: .missingResult)
                    }
                }
                Section("기타") {
                    Button("로그인 문제") {
                        open(.loginProblem, result: .missingResult)
                    }
                }
            }
            .navigationTitle(loggedIn ? "로그인 완료" : "로그인 시나리오")
            .navigationDestination(for: AuthRoute.self) { route in
                if route == .preferenceSelection || route == .findPassword {
                    Text("레거시 화면: \(String(describing: route))")
                } else {
                    builder?.make(route)
                }
            }
        }
    }

    private func open(_ route: AuthRoute, result: EmailLoginResult) {
        builder = AuthBuilder(
            dependencies: AuthDependencies(
                authClient: MockAuthClient(emailLoginResult: .success(result)),
                navigator: navigator,
                analytics: RecordingTracker(),
                onLoginCompleted: {
                    loggedIn = true
                    navigator.popToRoot()
                }
            )
        )
        navigator.push(route)
    }
}
