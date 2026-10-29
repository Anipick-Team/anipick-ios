import DetailInterface
import DetailTesting
import FeatureTestSupport
import MyInfoClientInterface
import MyInfoClientTesting
import MyInfoFeature
import MyInfoInterface
import ReviewClientTesting
import ReviewInterface
import SwiftUI

/// 서버 없이 마이페이지 목록 화면을 띄운다.
@main
struct MyInfoExampleApp: App {
    var body: some Scene {
        WindowGroup {
            ExampleRoot()
        }
    }
}

struct ExampleRoot: View {
    @State private var navigator = ExampleNavigator()
    @State private var builder: MyInfoBuilder?

    private static let filled = MockMyInfoClient.Scenario(
        animePage: .success(
            MyPage(
                count: 9, items: (1...9).map { .sample($0, rating: $0 % 2 == 0 ? 4.5 : nil) },
                lastId: 9)),
        personPage: .success(MyPage(count: 6, items: (1...6).map { .sample($0) }, lastId: 6)),
        ratedPages: [
            .success(
                RatedPage(
                    count: 9, lastId: 9,
                    reviews: (1...9).map {
                        .sample(
                            $0,
                            content: $0 % 3 == 0
                                ? nil : String(repeating: "긴 리뷰 내용 ", count: $0 * 3))
                    }))
        ]
    )

    var body: some View {
        NavigationStack(path: $navigator.path) {
            List {
                Section("목록 있음") {
                    routes(Self.filled)
                }
                Section("비어 있음") {
                    routes(MockMyInfoClient.Scenario())
                }
            }
            .navigationTitle("마이페이지 목록")
            .navigationDestination(for: MyInfoRoute.self) { route in
                builder?.make(route)
            }
            .navigationDestination(for: DetailRoute.self) { route in
                FakeDetailBuilder().make(route)
            }
            .navigationDestination(for: ReviewRoute.self) { route in
                Text("Review: \(String(describing: route))")
            }
        }
    }

    @ViewBuilder
    private func routes(_ scenario: MockMyInfoClient.Scenario) -> some View {
        ForEach(
            [
                ("볼 애니", MyInfoRoute.watchList), ("보는 중", .watching), ("다 본 애니", .finished),
                ("좋아요한 작품", .likedAnimes), ("좋아요한 인물", .likedPersons),
                ("평가한 작품", .ratedReviews),
            ],
            id: \.0
        ) { title, route in
            Button(title) {
                builder = MyInfoBuilder(
                    dependencies: MyInfoDependencies(
                        myInfoClient: MockMyInfoClient(scenario),
                        reviewClient: MockReviewClient(),
                        navigator: navigator
                    )
                )
                navigator.push(route)
            }
        }
    }
}
