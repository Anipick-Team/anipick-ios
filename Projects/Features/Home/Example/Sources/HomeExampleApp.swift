import FeatureTestSupport
import HomeClientInterface
import HomeClientTesting
import HomeFeature
import HomeInterface
import ReviewClientTesting
import SwiftUI

/// 서버 없이 홈 화면들을 띄운다.
@main
struct HomeExampleApp: App {
    var body: some Scene {
        WindowGroup {
            ExampleRoot()
        }
    }
}

struct ExampleRoot: View {
    @State private var navigator = ExampleNavigator()

    var body: some View {
        let client = MockHomeClient(delay: .milliseconds(300))
        let _ = client.stubRecommendations([
            .success(
                RecommendationPage(
                    animes: (1...18).map { .sample($0) }, referenceAnimeTitle: "원피스", lastId: nil,
                    lastValue: nil))
        ])
        NavigationStack(path: $navigator.path) {
            HomeBuilder(
                dependencies: HomeDependencies(
                    homeClient: client, reviewClient: MockReviewClient(), navigator: navigator,
                    cachedNickname: { "하노" },
                    imageURL: { URL(string: "https://example.invalid/api/image/\($0)")! })
            )
            .make(.recommendations(animeId: 1, animeTitle: nil))
            .navigationDestination(for: HomeRoute.self) { route in
                Text("레거시 화면: \(String(describing: route))")
            }
        }
    }
}
