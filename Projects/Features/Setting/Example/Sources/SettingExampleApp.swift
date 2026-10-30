import AuthClientTesting
import FeatureTestSupport
import Navigation
import SettingFeature
import SettingInterface
import SwiftUI
import UserClientTesting

/// 서버·로그인 없이 설정 화면을 시나리오별로 띄운다.
@main
struct SettingExampleApp: App {
    var body: some Scene {
        WindowGroup {
            ExampleRoot()
        }
    }
}

extension MockUserClient.Scenario {
    enum Name: String, CaseIterable, Hashable {
        case success = "성공"
        case duplicated = "이미 사용 중"
        case invalidFormat = "형식 오류"
        case empty = "빈 값"
        case offline = "오프라인 (변화 없음)"

        var scenario: MockUserClient.Scenario {
            switch self {
            case .success:
                return .success
            case .duplicated:
                return .duplicated
            case .invalidFormat:
                return .init(editNicknameResult: .failure(.invalidFormat))
            case .empty:
                return .init(editNicknameResult: .failure(.empty))
            case .offline:
                return .offline
            }
        }
    }
}

struct ExampleRoot: View {
    @State private var navigator = ExampleNavigator()
    @State private var builder: SettingBuilder?

    var body: some View {
        NavigationStack(path: $navigator.path) {
            List {
                Section("설정 메인") {
                    Button("이메일 가입") {
                        open(.main, scenario: .success)
                    }
                    Button("카카오 가입 (이메일·비밀번호 변경 막힘)") {
                        open(.main, scenario: .init(snsAccount: "KAKAO"))
                    }
                }
                Section("닉네임 변경") {
                    ForEach(MockUserClient.Scenario.Name.allCases, id: \.self) { name in
                        Button(name.rawValue) {
                            open(.editNickname, scenario: name.scenario)
                        }
                    }
                }
                Section("비밀번호 변경") {
                    Button("성공") {
                        open(.editPassword, scenario: .success)
                    }
                    Button("현재 비밀번호 틀림 (107)") {
                        open(
                            .editPassword,
                            scenario: .init(editPasswordResult: .failure(.currentPasswordMismatch)))
                    }
                    Button("확인 불일치 (108)") {
                        open(
                            .editPassword,
                            scenario: .init(editPasswordResult: .failure(.confirmationMismatch)))
                    }
                }
                Section("이메일 변경") {
                    Button("성공 → 완료 팝업 (확인은 이 앱에서 이동 없음)") {
                        open(.editEmail, scenario: .success)
                    }
                    Button("형식 오류 (103)") {
                        open(
                            .editEmail,
                            scenario: .init(editEmailResult: .failure(.invalidEmailFormat)))
                    }
                    Button("비밀번호 틀림 (106)") {
                        open(
                            .editEmail,
                            scenario: .init(editEmailResult: .failure(.passwordMismatch)))
                    }
                }
                Section("회원 탈퇴") {
                    Button("성공 (이 앱에서는 이동 없음 — 로그인 화면 전환은 App의 Session)") {
                        open(.withdrawal, scenario: .success)
                    }
                    Button("거절") {
                        open(.withdrawal, scenario: .init(withdrawalResult: .failure(.rejected)))
                    }
                }
            }
            .navigationTitle("설정 시나리오")
            .navigationDestination(for: SettingRoute.self) { route in
                builder?.make(route)
            }
        }
    }

    private func open(_ route: SettingRoute, scenario: MockUserClient.Scenario) {
        builder = SettingBuilder(
            dependencies: SettingDependencies(
                userClient: MockUserClient(scenario),
                authClient: MockAuthClient(),
                navigator: navigator,
                openURL: { print("외부 링크: \($0)") },
                appVersion: "1.2.0"
            )
        )
        navigator.push(route)
    }
}
