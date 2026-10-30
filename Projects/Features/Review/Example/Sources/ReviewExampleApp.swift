import Analytics
import ClientCore
import FeatureTestSupport
import ReviewClientTesting
import ReviewFeature
import ReviewInterface
import SwiftUI

/// 서버·로그인 없이 리뷰 작성 화면을 시나리오별로 띄운다.
@main
struct ReviewExampleApp: App {
    var body: some Scene {
        WindowGroup {
            ExampleRoot()
        }
    }
}

struct ExampleRoot: View {
    @State private var navigator = ExampleNavigator()
    @State private var builder: ReviewBuilder?

    var body: some View {
        NavigationStack(path: $navigator.path) {
            List {
                Section("리뷰 작성") {
                    Button("새 리뷰 (별점 3.5)") {
                        open(
                            .write(animeId: 1, rating: 3.5, content: ""),
                            client: MockReviewClient()
                        )
                    }
                    Button("기존 리뷰 수정") {
                        open(
                            .write(animeId: 1, rating: 4, content: "다시 봐도 재밌는 작품"),
                            client: MockReviewClient()
                        )
                    }
                    Button("저장 실패 (오프라인 — 화면은 똑같이 닫힘)") {
                        open(
                            .write(animeId: 1, rating: 0, content: ""),
                            client: MockReviewClient(result: .failure(.offline))
                        )
                    }
                }
            }
            .navigationTitle("리뷰 시나리오")
            .navigationDestination(for: ReviewRoute.self) { route in
                builder?.make(route)
            }
        }
    }

    private func open(_ route: ReviewRoute, client: MockReviewClient) {
        builder = ReviewBuilder(
            dependencies: ReviewDependencies(
                reviewClient: client,
                navigator: navigator,
                analytics: RecordingTracker()
            )
        )
        navigator.push(route)
    }
}
