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

@Observable
final class ExampleNavigator: Navigator {
    var path = NavigationPath()

    func push(_ route: some Hashable & Sendable) {
        path.append(route)
    }

    func pop() {
        guard !path.isEmpty else {
            return
        }
        path.removeLast()
    }

    func popToRoot() {
        path = NavigationPath()
    }

    func present(_ route: some Hashable & Sendable) {}

    func dismiss() {}
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
                Section("닉네임 변경") {
                    ForEach(MockUserClient.Scenario.Name.allCases, id: \.self) { name in
                        Button(name.rawValue) {
                            open(.editNickname, scenario: name.scenario)
                        }
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
                navigator: navigator
            )
        )
        navigator.push(route)
    }
}
