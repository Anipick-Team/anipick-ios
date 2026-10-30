import ClientCore
import DetailClientInterface
import DetailClientTesting
import DetailInterface
import FeatureTestSupport
import MVICore
import Testing

@testable import DetailFeature

/// 동작 목록 VA2~VA6 (notes/2026-10-30-R-detail-03-voice-actor.md)과 1:1
@Suite("성우 상세", .timeLimit(.minutes(1)))
struct VoiceActorReducerTests {
    private let navigator = RecordingNavigator()
    private let client = MockDetailClient()

    private func page(_ ids: [Int], lastId: Int, liked: Bool = false) -> Result<
        PersonPage, TransportError
    > {
        return .success(
            PersonPage(
                name: "카지", profileImageUrl: nil, isLiked: liked, count: 40, lastId: lastId,
                works: ids.map { .sample($0) }))
    }

    private func makeStore() -> Store<VoiceActorReducer> {
        return Store(
            initialState: .init(personId: 3),
            reducer: VoiceActorReducer(detailClient: client, navigator: navigator))
    }

    @Test("VA2. 처음 보일 때 한 번만 받는다. 이름·사진(없으면 \"\")·개수·좋아요·커서")
    func loadsOnce() async {
        client.stubPerson([page([1, 2], lastId: 2, liked: true)])
        let store = makeStore()

        await store.send(.appeared).finish()
        await store.send(.appeared).finish()

        #expect(store.state.name == "카지")
        #expect(store.state.imageUrl == "")
        #expect(store.state.workCount == 40)
        #expect(store.state.isLiked)
        #expect(store.state.works.map(\.characterId) == [1, 2])
        #expect(client.requests == [.person(id: 3, lastId: nil)])
    }

    @Test("VA3. 마지막 배역이 보이면 커서로 이어 붙인다 (끝인지는 보지 않는다)")
    func loadsMore() async {
        client.stubPerson([page([1, 2], lastId: 2), page([3], lastId: 3)])
        let store = makeStore()
        await store.send(.appeared).finish()

        await store.send(.workAppeared(.sample(1))).finish()
        await store.send(.workAppeared(.sample(2))).finish()
        await store.send(.workAppeared(.sample(3))).finish()

        #expect(store.state.works.map(\.characterId) == [1, 2, 3, 3])
        #expect(
            client.requests == [
                .person(id: 3, lastId: nil), .person(id: 3, lastId: 2), .person(id: 3, lastId: 3),
            ])
    }

    @Test("VA4. 실패하면 그대로")
    func failure() async {
        client.stubPerson([.failure(.decoding)])
        let store = makeStore()

        await store.send(.appeared).finish()

        #expect(store.state.name == "")
    }

    @Test("VA5. 좋아요: 화면을 먼저 바꾸고 상태에 맞춰 POST·DELETE")
    func like() async {
        let store = makeStore()

        await store.send(.likeTapped).finish()
        #expect(store.state.isLiked)
        await store.send(.likeTapped).finish()

        #expect(!store.state.isLiked)
        #expect(
            client.requests == [.personLike(id: 3, liked: true), .personLike(id: 3, liked: false)])
    }

    @Test("VA6. 배역을 누르면 그 애니 상세로, 뒤로는 pop")
    func navigation() async {
        let store = makeStore()

        await store.send(.workTapped(.sample(1))).finish()
        await store.send(.backTapped).finish()

        #expect(navigator.actions == [.push(DetailRoute.anime(id: 11)), .pop])
    }
}
