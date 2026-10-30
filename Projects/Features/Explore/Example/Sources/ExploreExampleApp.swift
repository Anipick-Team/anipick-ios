import CommunityClientInterface
import CommunityClientTesting
import ExploreClientInterface
import ExploreClientTesting
import ExploreFeature
import MetadataClientTesting
import ExploreInterface
import FeatureTestSupport
import SwiftUI

/// 서버 없이 탐색 커뮤니티 목록을 띄운다.
@main
struct ExploreExampleApp: App {
    var body: some Scene {
        WindowGroup {
            ExampleRoot()
        }
    }
}

struct ExampleRoot: View {
    @State private var navigator = ExampleNavigator()

    var body: some View {
        NavigationStack(path: $navigator.path) {
            ExploreBuilder(
                dependencies: ExploreDependencies(
                    communityClient: MockCommunityClient(
                        boards: [
                            .success(
                                CommunityBoardPage(
                                    boards: (1...15).map { .sample($0) }, lastId: nil,
                                    lastValue: nil))
                        ],
                        delay: .milliseconds(400)),
                    exploreClient: MockExploreClient(
                        explorePages: [
                            .success(ExplorePage(animes: (1...30).map { .sample($0) }, lastId: nil))
                        ]),
                    metadataClient: MockMetadataClient(),
                    navigator: navigator
                )
            )
            .make(.main)
            .navigationDestination(for: ExploreRoute.self) { route in
                Text("레거시 화면: \(String(describing: route))")
            }
        }
    }
}
