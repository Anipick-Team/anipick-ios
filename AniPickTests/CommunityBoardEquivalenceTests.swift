//
//  CommunityBoardEquivalenceTests.swift
//  AniPickTests
//
//  이관한 커뮤니티 게시판이 레거시와 같은 모양인지 픽셀로 비교한다 (R Explore 4).
//  레거시는 ViewModel을 안에서 만들어(@StateObject private) 목록을 넣을 수 없다. 처음 화면(받는 중)만 비교한다.
//  레거시는 만들 때 운영 서버에 글 목록을 요청한다. 응답은 스냅샷 뒤에 오므로 결과에는 영향이 없다.
//

import CommunityClientTesting
import Navigation
import SwiftUI
import Testing

@testable import AniPick
@testable import ExploreFeature

@MainActor
@Suite("커뮤니티 게시판 ↔ 레거시", .serialized)
struct CommunityBoardEquivalenceTests {
    private func legacy(_ title: String, genres: [String]) -> some View {
        return AniPick.CommunityView(seriesId: 1, animeTitle: title, coverImageUrl: nil, genreNames: genres)
            .environmentObject(NavigationManager())
    }

    private func new(_ title: String, genres: [String]) -> some View {
        return ExploreFeature.CommunityBoardView(
            state: CommunityBoardReducer.State(seriesId: 1, animeTitle: title, coverImageUrl: nil, genreNames: genres),
            reducer: CommunityBoardReducer(
                communityClient: MockCommunityClient(delay: .seconds(5)),
                navigator: LegacyNavigator(navigationManager: NavigationManager())))
    }

    @Test(
        "처음 화면(애니 정보·필터·스포일러·받는 중)이 같다",
        arguments: [
            ("진격의 거인", ["액션", "드라마", "판타지"]),
            ("아주 긴 제목의 애니메이션 작품 이름이 두 줄을 넘어가는 경우를 확인합니다", ["SF"]), ("장르 없음", []),
        ] as [(String, [String])]
    )
    func initial(title: String, genres: [String]) throws {
        #expect(try hostedSnapshot(legacy(title, genres: genres)) == hostedSnapshot(new(title, genres: genres)))
    }

    @Test("통제: 장르가 다르면 픽셀이 다르다")
    func detectsGenres() throws {
        #expect(try hostedSnapshot(legacy("a", genres: ["액션"])) != hostedSnapshot(new("a", genres: ["드라마"])))
    }
}
