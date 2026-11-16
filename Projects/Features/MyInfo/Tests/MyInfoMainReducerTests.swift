import ClientCore
import DetailInterface
import FeatureTestSupport
import Foundation
import MVICore
import MyInfoClientInterface
import MyInfoClientTesting
import MyInfoInterface
import SettingInterface
import Testing
import UIKit
import os

@testable import MyInfoFeature

/// 동작 목록 MM1~MM12 (notes/2026-10-29-R-myinfo-04-main.md)과 1:1
@Suite("마이페이지 메인", .timeLimit(.minutes(1)))
struct MyInfoMainReducerTests {
    private let navigator = RecordingNavigator()
    private let openedURLs = OSAllocatedUnfairLock(initialState: [URL]())
    private let png = UIGraphicsImageRenderer(size: CGSize(width: 2, height: 2)).pngData { _ in }

    private func makeStore(_ scenario: MockMyInfoClient.Scenario) -> (
        Store<MyInfoMainReducer>, MockMyInfoClient
    ) {
        let client = MockMyInfoClient(scenario)
        let store = Store(
            initialState: MyInfoMainReducer.State(),
            reducer: MyInfoMainReducer(
                myInfoClient: client, navigator: navigator,
                openURL: { [openedURLs] url in openedURLs.withLock { $0.append(url) } })
        )
        return (store, client)
    }

    private var profile: MyProfile {
        return MyProfile(
            profileImageUrl: "https://anipick.p-e.kr/api/image/42",
            watchCounts: .init(watchList: 1, watching: nil, finished: 3),
            likedAnimes: [.sample(1), .sample(2)])
    }

    @Test("MM1·MM2·MM4. 보일 때마다 정보·좋아요한 인물을 받고, 프로필 주소의 마지막 경로를 id로 이미지를 받는다")
    func loadsOnAppear() async {
        let (store, client) = makeStore(
            .init(
                personPage: .success(MyPage(count: 1, items: [.sample(9)], lastId: 9)),
                profile: .success(profile), profileImage: .success(png)))

        await store.send(.appeared).finish()

        #expect(await waitUntil { store.state.profileImage == png })
        #expect(store.state.watchListCount == 1)
        #expect(store.state.watchingCount == 0)
        #expect(store.state.finishedCount == 3)
        #expect(store.state.likedAnimes.map(\.animeId) == [1, 2])
        #expect(store.state.likedPersons.map(\.personId) == [9])
        #expect(client.requests.contains(.profileImage(id: 42)))
        #expect(client.requests.contains(.likedPersons(lastId: nil)))
    }

    @Test("MM1. 개수가 없으면 좋아요한 작품·프로필 이미지도 건너뛴다")
    func skipsWithoutCounts() async {
        let (store, client) = makeStore(
            .init(
                profile: .success(
                    MyProfile(profileImageUrl: "x/5", watchCounts: nil, likedAnimes: [.sample(1)])))
        )

        await store.send(.appeared).finish()

        #expect(store.state.likedAnimes.isEmpty)
        #expect(!client.requests.contains(.profileImage(id: 5)))
    }

    @Test("MM2. 이미지로 읽히지 않는 응답이면 기본 이미지로 둔다. id를 못 읽으면 0으로 요청한다")
    func invalidImage() async {
        let (store, client) = makeStore(
            .init(
                profile: .success(
                    MyProfile(
                        profileImageUrl: nil,
                        watchCounts: .init(watchList: 0, watching: 0, finished: 0), likedAnimes: nil
                    )),
                profileImage: .success(Data("not image".utf8))))

        await store.send(.appeared).finish()

        #expect(await waitUntil { client.requests.contains(.profileImage(id: 0)) })
        #expect(store.state.profileImage == nil)
        #expect(MyInfoMainReducer.imageId(from: "https://a/api/image/17") == 17)
        #expect(MyInfoMainReducer.imageId(from: "https://a/api/image/abc") == 0)
    }

    @Test("MM3·MM5·MM9. 설정·목록·상세로 이동하고 피드백은 설문을 연다")
    func navigation() async {
        let (store, _) = makeStore(.init())

        await store.send(.settingTapped).finish()
        await store.send(.routeTapped(.watching)).finish()
        await store.send(.routeTapped(.ratedReviews)).finish()
        await store.send(.animeTapped(.sample(3))).finish()
        await store.send(.personTapped(.sample(4))).finish()
        await store.send(.feedbackTapped).finish()

        #expect(
            navigator.actions
                == [
                    .push(SettingRoute.main), .push(MyInfoRoute.watching),
                    .push(MyInfoRoute.ratedReviews), .push(DetailRoute.anime(id: 3)),
                    .push(DetailRoute.voiceActor(id: 4)),
                ])
        #expect(openedURLs.withLock { $0 } == [MyInfoMainReducer.feedbackURL])
    }

    @Test(
        "MM6·MM7·MM8. 사진을 고르면 올리는 동안 창을 열어 두고, 끝나면(실패해도) 닫은 뒤 정보를 다시 받는다", arguments: [true, false])
    func upload(succeeds: Bool) async {
        let (store, client) = makeStore(.init(upload: succeeds ? .success(7) : .failure(.offline)))
        await store.send(.editProfileTapped).finish()
        #expect(store.state.isImagePickerPresented)

        let effect = store.send(.imagePicked(Data([1, 2, 3])))
        #expect(store.state.isImagePickerPresented)
        await effect.finish()

        #expect(store.state.isImagePickerPresented == false)
        #expect(await waitUntil { client.requests.contains(.profile) })
        #expect(client.requests.first == .upload(bytes: 3))
    }

    @Test("MM8. 사진 선택을 취소하면 닫고 정보를 다시 받는다. 닫혀 있을 때 닫기 신호는 무시한다")
    func cancelPicker() async {
        let (store, client) = makeStore(.init())
        await store.send(.imagePickerPresentedChanged(false)).finish()
        #expect(client.requests.isEmpty)
        await store.send(.editProfileTapped).finish()

        await store.send(.imagePickerPresentedChanged(false)).finish()

        #expect(await waitUntil { client.requests == [.profile] })
    }
}
