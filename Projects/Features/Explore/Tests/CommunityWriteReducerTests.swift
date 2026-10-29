import ClientCore
import CommunityClientInterface
import CommunityClientTesting
import FeatureTestSupport
import Foundation
import MVICore
import PhotosUI
import SwiftUI
import Testing
import UIKit
import os

@testable import ExploreFeature

/// 동작 목록 CW6~CW16 (notes/2026-10-30-R-explore-03-community-write.md)과 1:1
@Suite("커뮤니티 글쓰기", .timeLimit(.minutes(1)))
struct CommunityWriteReducerTests {
    private let navigator = RecordingNavigator()
    private let client = MockCommunityClient()
    private let updated = OSAllocatedUnfairLock<[Int]>(initialState: [])
    /// 사진 id → 원본 데이터 (없으면 불러오기 실패)
    private let photos = OSAllocatedUnfairLock<[String: Data]>(initialState: [:])

    private nonisolated static let png = UIGraphicsImageRenderer(size: CGSize(width: 4, height: 4))
        .pngData {
            context in
            UIColor.red.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 4, height: 4))
        }

    private func item(_ id: String, loads: Bool = true) -> PhotosPickerItem {
        if loads {
            photos.withLock { $0[id] = Self.png }
        }
        return PhotosPickerItem(itemIdentifier: id)
    }

    private func makeStore(
        _ state: CommunityWriteReducer.State, maxImageBytes: Int = 10 * 1024 * 1024
    )
        -> Store<CommunityWriteReducer>
    {
        return Store(
            initialState: state,
            reducer: CommunityWriteReducer(
                communityClient: client, navigator: navigator,
                loadPhoto: { [photos] item in photos.withLock { $0[item.itemIdentifier ?? ""] } },
                postUpdated: { [updated] id in updated.withLock { $0.append(id) } },
                maxImageBytes: maxImageBytes,
                feedbackDuration: .milliseconds(20),
                dismissDelay: .milliseconds(10)))
    }

    private func sources(_ store: Store<CommunityWriteReducer>) -> [String] {
        return store.state.images.map {
            switch $0.source {
            case .remote(let id):
                return "remote:\(id)"
            case .local(_, _, let item):
                return "local:\(item.itemIdentifier ?? "")"
            }
        }
    }

    @Test("CW6. 제목은 50자, 내용은 1000자까지. 제목을 바꾸면 제목 오류를 지운다")
    func limits() async {
        let store = makeStore(.init(seriesId: 1))
        await store.send(.registerTapped).finish()
        #expect(store.state.titleError)

        await store.send(.titleChanged(String(repeating: "가", count: 51))).finish()
        await store.send(.contentChanged(String(repeating: "a", count: 1001))).finish()

        #expect(store.state.title.count == 50)
        #expect(store.state.content.count == 1000)
        #expect(!store.state.titleError)
    }

    @Test("CW7. 수정 진입은 기존 제목·내용·스포일러·사진으로 채운다. 남은 선택 장수는 5 - 서버 사진")
    func editingState() {
        let state = CommunityWriteReducer.State(
            seriesId: 1, postId: 9, title: "t", content: "c", isSpoiler: true, imageIds: [4, 5])

        #expect(state.images.map(\.source) == [.remote(imageId: 4), .remote(imageId: 5)])
        #expect(state.remainingPickerCount == 3)
        #expect(state.isSpoiler)
    }

    @Test("CW8. 사진을 고르면 새로 고른 것만 불러와 서버 사진 뒤에 붙인다. 선택에서 빠진 사진은 뺀다")
    func picksPhotos() async {
        let store = makeStore(.init(seriesId: 1, postId: 9, imageIds: [4]))
        let a = item("a")
        let b = item("b")
        let c = item("c")

        await store.send(.photosPicked([a, b])).finish()
        #expect(sources(store) == ["remote:4", "local:a", "local:b"])

        await store.send(.photosPicked([b, c])).finish()
        #expect(sources(store) == ["remote:4", "local:b", "local:c"])
        #expect(store.state.imageError == nil)
    }

    @Test("CW9. 남은 장수보다 많이 고르면 안내하고 앞의 것만 남긴다 (모두 불러오면 안내는 지워진다)")
    func overLimit() async {
        let store = makeStore(.init(seriesId: 1, postId: 9, imageIds: [1, 2, 3, 4]))

        let effect = store.send(.photosPicked([item("a"), item("b")]))
        #expect(store.state.imageError == "사진은 최대 5장까지 첨부할 수 있어요.")
        #expect(store.state.selectedPhotos.map(\.itemIdentifier) == ["a"])
        await effect.finish()

        #expect(sources(store) == ["remote:1", "remote:2", "remote:3", "remote:4", "local:a"])
        #expect(store.state.imageError == nil)
    }

    @Test("CW10. 10MB(압축 후)를 넘으면 빼고 안내한다. 불러오기 실패는 빼기만 하고 안내를 바꾸지 않는다")
    func failures() async {
        let store = makeStore(.init(seriesId: 1), maxImageBytes: 1)

        await store.send(.photosPicked([item("a"), item("b", loads: false)])).finish()

        #expect(store.state.images.isEmpty)
        #expect(store.state.imageError == "사진 1장당 최대 10MB까지 첨부할 수 있어요.")
    }

    @Test("CW11. 사진을 지우면 목록과 선택에서 뺀다. 고른 사진을 지우면 사진 안내도 지운다. 끌어 놓으면 그 자리로")
    func removeAndMove() async {
        let store = makeStore(.init(seriesId: 1, postId: 9, imageIds: [1, 2]))
        await store.send(.photosPicked([item("a")])).finish()

        let ids = store.state.images.map(\.id)
        await store.send(.imageMoved(dragging: ids[2], onto: ids[0])).finish()
        #expect(sources(store) == ["local:a", "remote:1", "remote:2"])
        await store.send(.imageMoved(dragging: ids[2], onto: ids[0])).finish()
        #expect(sources(store) == ["remote:1", "local:a", "remote:2"])

        await store.send(.imageRemoved(ids[0])).finish()
        #expect(sources(store) == ["local:a", "remote:2"])
        await store.send(.imageRemoved(ids[2])).finish()
        #expect(sources(store) == ["remote:2"])
        #expect(store.state.selectedPhotos.isEmpty)
    }

    @Test("CW12. 등록: 제목이 비면(공백만) 오류만, 사진 안내가 있으면 아무것도 보내지 않는다")
    func validation() async {
        let store = makeStore(.init(seriesId: 1, title: "  \n"))
        await store.send(.registerTapped).finish()
        #expect(store.state.titleError)

        let oversized = makeStore(.init(seriesId: 1, title: "t"), maxImageBytes: 1)
        await oversized.send(.photosPicked([item("a")])).finish()
        await oversized.send(.registerTapped).finish()

        #expect(!oversized.state.isRegistering)
        #expect(client.saveRequests.isEmpty)
    }

    @Test("CW13. 새 글: 화면 순서대로 새 사진만 올리고(번호는 위치), 앞뒤 공백을 지워 작성한다. 내용은 비어도 된다 (PR #16)")
    func create() async {
        client.stubSave(uploads: [.success(31), .success(nil)])
        let store = makeStore(.init(seriesId: 7, title: " 제목 ", content: "   "))
        await store.send(.photosPicked([item("a"), item("b")])).finish()

        await store.send(.registerTapped).finish()

        let bytes = Self.uploadSize(client.saveRequests.first)
        #expect(
            client.saveRequests
                == [
                    .upload(fileName: "community-post-1.jpg", bytes: bytes),
                    .upload(fileName: "community-post-2.jpg", bytes: bytes),
                    .create(
                        seriesId: 7,
                        PostDraft(title: "제목", content: "", isSpoiler: false, imageIds: [31])),
                ])
        #expect(await waitUntil { navigator.actions == [.pop] })
        #expect(await waitUntil { store.state.feedbackMessage == nil })
        #expect(updated.withLock { $0 }.isEmpty)
    }

    @Test("CW14. 수정: 서버 사진 id는 그대로, 모두 PATCH로 저장하고 App에 알린 뒤 닫는다. 저장 중에는 다시 누를 수 없다 (PR #17)")
    func update() async {
        let store = makeStore(
            .init(seriesId: 7, postId: 9, title: "t", content: "c", isSpoiler: true, imageIds: [5]))

        let first = store.send(.registerTapped)
        #expect(store.state.isRegistering)
        await store.send(.registerTapped).finish()
        await first.finish()

        #expect(
            client.saveRequests == [
                .update(id: 9, PostDraft(title: "t", content: "c", isSpoiler: true, imageIds: [5]))
            ])
        #expect(updated.withLock { $0 } == [9])
        #expect(store.state.isRegistering)
        #expect(await waitUntil { navigator.actions == [.pop] })
    }

    @Test(
        "CW15. 성공하면 안내가 뜨고 잠시 뒤 닫는다",
        arguments: [(nil, "게시글이 등록되었습니다."), (9, "게시글이 수정되었습니다.")] as [(Int?, String)])
    func successFeedback(postId: Int?, message: String) async {
        let store = Store(
            initialState: CommunityWriteReducer.State(seriesId: 1, postId: postId, title: "t"),
            reducer: CommunityWriteReducer(
                communityClient: client, navigator: navigator, loadPhoto: { _ in nil },
                postUpdated: { _ in },
                feedbackDuration: .seconds(5), dismissDelay: .milliseconds(10)))

        let effect = store.send(.registerTapped)
        #expect(await waitUntil { navigator.actions == [.pop] })

        #expect(store.state.feedbackMessage == message)
        _ = effect
    }

    @Test("CW16. 거절되면 서버 문구(없으면 기본), 실패하면 기본 문구. 다시 누를 수 있고 안내는 잠시 뒤 사라진다")
    func failuresOnSave() async {
        client.stubSave(result: .success(.rejected(message: "금지어가 있어요.")))
        let store = makeStore(.init(seriesId: 1, title: "t"))

        let effect = store.send(.registerTapped)
        #expect(await waitUntil { store.state.feedbackMessage == "금지어가 있어요." })
        #expect(!store.state.isRegistering)
        await effect.finish()
        #expect(await waitUntil { store.state.feedbackMessage == nil })

        client.stubSave(result: .success(.rejected(message: nil)))
        let rejected = store.send(.registerTapped)
        #expect(
            await waitUntil { store.state.feedbackMessage == CommunityWriteReducer.failureMessage })
        await rejected.finish()
        #expect(await waitUntil { store.state.feedbackMessage == nil })

        client.stubSave(uploads: [.failure(.offline)])
        await store.send(.photosPicked([item("a")])).finish()
        let failed = store.send(.registerTapped)
        #expect(
            await waitUntil { store.state.feedbackMessage == CommunityWriteReducer.failureMessage })
        await failed.finish()
        #expect(!store.state.isRegistering)
        #expect(navigator.actions.isEmpty)
    }

    @Test("CW5. 뒤로 버튼은 pop")
    func back() async {
        let store = makeStore(.init(seriesId: 1))

        await store.send(.backTapped).finish()

        #expect(navigator.actions == [.pop])
    }

    private static func uploadSize(_ request: MockCommunityClient.SaveRequest?) -> Int {
        guard case .upload(_, let bytes) = request else {
            return -1
        }
        return bytes
    }
}
