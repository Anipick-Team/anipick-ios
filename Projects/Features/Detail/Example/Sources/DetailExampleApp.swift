import CommunityClientTesting
import DetailClientInterface
import DetailClientTesting
import DetailFeature
import DetailInterface
import FeatureTestSupport
import ReviewClientTesting
import SwiftUI

/// 서버 없이 상세 화면들을 띄운다.
@main
struct DetailExampleApp: App {
    var body: some Scene {
        WindowGroup {
            ExampleRoot()
        }
    }
}

struct ExampleRoot: View {
    @State private var navigator = ExampleNavigator()

    var body: some View {
        let client = MockDetailClient(delay: .milliseconds(300))
        let _ = client.stubSeries([
            .success(SeriesPage(animes: (1...12).map { .sample($0) }, count: 12, lastId: nil))
        ])
        NavigationStack(path: $navigator.path) {
            DetailBuilder(
                dependencies: DetailDependencies(
                    detailClient: client, reviewClient: MockReviewClient(),
                    communityClient: MockCommunityClient(),
                    navigator: navigator,
                    analytics: RecordingTracker())
            )
            .make(.series(animeId: 1, animeTitle: "원피스"))
            .navigationDestination(for: DetailRoute.self) { route in
                Text("레거시 화면: \(String(describing: route))")
            }
        }
    }
}
