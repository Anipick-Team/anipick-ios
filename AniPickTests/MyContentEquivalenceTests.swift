//
//  MyContentEquivalenceTests.swift
//  AniPickTests
//
//  이관한 내 콘텐츠 화면이 레거시와 같은 모양인지 픽셀로 비교한다 (R MyInfo 3).
//  레거시 `MyContentView`는 ViewModel을 안에서 만들어 데이터를 넣을 수 없다 — 처음(비어 있는) 화면만 비교한다.
//  레거시는 보일 때 실제 서버에 요청한다. 응답은 스냅샷 뒤에 오므로 결과에는 영향이 없다.
//

import FeatureTestSupport
import MyInfoClientTesting
import Navigation
import SwiftUI
import Testing

@testable import AniPick
@testable import MyInfoFeature

@MainActor
@Suite("내 콘텐츠 ↔ 레거시", .serialized)
struct MyContentEquivalenceTests {
    private func new(totalCount: Int = 0) -> some View {
        var state = MyContentReducer.State()
        state.totalCount = totalCount
        return MyInfoFeature.MyContentView(
            state: state,
            reducer: MyContentReducer(
                myInfoClient: MockMyInfoClient(contentDelaySeconds: 10),
                navigator: LegacyNavigator(navigationManager: NavigationManager()),
                openTab: { _ in })
        )
    }

    private func legacy() -> some View {
        return AniPick.MyContentView().environmentObject(NavigationManager())
    }

    @Test("처음 화면(내 게시글 탭, 총 0개, 아래 탭 바)이 같다")
    func initial() throws {
        #expect(try hostedSnapshot(legacy()) == hostedSnapshot(new()))
    }

    @Test("통제: 총 개수가 다르면 픽셀이 다르다")
    func detectsCount() throws {
        #expect(try hostedSnapshot(legacy()) != hostedSnapshot(new(totalCount: 5)))
    }
}

extension MockMyInfoClient {
    /// 응답을 늦춰 스냅샷 동안 빈 화면을 유지한다
    convenience init(contentDelaySeconds: Int) {
        self.init(.init(contentDelay: .seconds(contentDelaySeconds)))
    }
}
