import ClientCore
import DetailInterface
import DetailTesting
import FeatureTestSupport
import HomeInterface
import HomeTesting
import MetadataClientTesting
import RankingClientInterface
import RankingClientTesting
import RankingFeature
import RankingInterface
import SwiftUI

/// 서버 없이 랭킹 탭을 띄운다. 페이지를 넘길 때마다 20개씩 더 준다.
@main
struct RankingExampleApp: App {
    var body: some Scene {
        WindowGroup {
            ExampleRoot()
        }
    }
}

struct ExampleRoot: View {
    @State private var navigator = ExampleNavigator()
    @State private var builder: RankingBuilder?

    var body: some View {
        NavigationStack(path: $navigator.path) {
            Group {
                if let builder {
                    builder.make(.main)
                } else {
                    ProgressView()
                }
            }
            .navigationDestination(for: DetailRoute.self) { route in
                FakeDetailBuilder().make(route)
            }
            .navigationDestination(for: HomeRoute.self) { route in
                FakeHomeBuilder().make(route)
            }
        }
        .onAppear {
            builder = RankingBuilder(
                dependencies: RankingDependencies(
                    rankingClient: MockRankingClient(Self.pages, delay: .milliseconds(300)),
                    metadataClient: MockMetadataClient(),
                    navigator: navigator
                )
            )
        }
    }

    private static let pages: [Result<RankingPage, TransportError>] = (0..<5).map { index in
        let start = index * 20 + 1
        let animes = (start..<start + 20).map { id in
            RankedAnime.sample(
                id: id,
                rank: id,
                trend: ["up", "down", "same"][id % 3],
                change: "\(id % 5)",
                genres: ["액션", "판타지", "코미디"].prefix(id % 3 + 1).map { $0 }
            )
        }
        return .success(RankingPage(animes: animes, lastId: start + 19, lastValue: "\(index)"))
    }
}
