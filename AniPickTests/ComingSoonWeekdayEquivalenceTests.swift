//
//  ComingSoonWeekdayEquivalenceTests.swift
//  AniPickTests
//
//  이관한 공개 예정·요일별 신작이 레거시와 같은 모양인지 픽셀로 비교한다 (R Home 2).
//  레거시는 보일 때 운영 서버에 요청한다. 응답은 스냅샷 뒤에 오므로 결과에는 영향이 없다.
//

import HomeClientInterface
import HomeClientTesting
import Navigation
import SwiftUI
import Testing

@testable import AniPick
@testable import HomeFeature

@MainActor
@Suite("공개 예정·요일별 신작 ↔ 레거시", .serialized)
struct ComingSoonWeekdayEquivalenceTests {
    struct Setup: Sendable {
        var ids = Array(1...5)
        var noDate: Set<Int> = []
        var sort = 0
        var menu = false
    }

    private func legacyComingSoon(_ setup: Setup) -> some View {
        let viewModel = ComingSoonViewModel(navigationManager: NavigationManager())
        viewModel.comingSoonAnimeList = setup.ids.map {
            UpcomingAnime(
                animeId: $0, title: "애니 \($0)", coverImageUrl: nil,
                releaseDate: setup.noDate.contains($0) ? nil : "2026.11.0\($0)", isAdult: false)
        }
        viewModel.selectedCategory = ComingSoonSortCategory.allCases[setup.sort]
        viewModel.isShowSortCategoryOptionView = setup.menu
        return AniPick.ComingSoonView(viewModel: viewModel)
    }

    private func newComingSoon(_ setup: Setup) -> some View {
        var state = ComingSoonReducer.State()
        state.items = setup.ids.map {
            ComingSoonAnime(
                animeId: $0, title: "애니 \($0)", coverImageUrl: nil,
                releaseDate: setup.noDate.contains($0) ? nil : "2026.11.0\($0)")
        }
        state.sort = ComingSoonReducer.Sort.allCases[setup.sort]
        state.isSortMenuPresented = setup.menu
        return HomeFeature.ComingSoonView(
            state: state,
            reducer: ComingSoonReducer(
                homeClient: MockHomeClient(delay: .seconds(5)),
                navigator: LegacyNavigator(navigationManager: NavigationManager())))
    }

    @Test(
        "공개 예정(목록·날짜 없는 칸·정렬·정렬 메뉴)이 같다",
        arguments: [Setup(), Setup(noDate: [2, 4], sort: 2), Setup(ids: [], sort: 1), Setup(menu: true)])
    func comingSoon(setup: Setup) throws {
        #expect(try hostedSnapshot(legacyComingSoon(setup)) == hostedSnapshot(newComingSoon(setup)))
    }

    @Test("통제: 공개일이 다르면 픽셀이 다르다")
    func detectsReleaseDate() throws {
        #expect(try hostedSnapshot(legacyComingSoon(Setup())) != hostedSnapshot(newComingSoon(Setup(noDate: [1]))))
    }

    private func newWeekday(day: Int) -> some View {
        return HomeFeature.WeekdayNewAnimeView(
            state: WeekdayNewAnimeReducer.State(day: WeekdayNewAnimeDay(rawValue: day)!),
            reducer: WeekdayNewAnimeReducer(
                homeClient: MockHomeClient(delay: .seconds(5)),
                navigator: LegacyNavigator(navigationManager: NavigationManager())))
    }

    @Test("요일별 신작 처음 화면(안내 배너·요일·정렬)이 같다", arguments: [1, 4, 7])
    func weekday(day: Int) throws {
        let legacy = AniPick.WeekdayNewAnimeView(
            viewModel: WeekdayNewAnimeViewModel(day: day, navigationManager: NavigationManager()))
        #expect(try hostedSnapshot(legacy) == hostedSnapshot(newWeekday(day: day)))
    }

    @Test("통제: 선택한 요일이 다르면 픽셀이 다르다")
    func detectsDay() throws {
        let legacy = AniPick.WeekdayNewAnimeView(
            viewModel: WeekdayNewAnimeViewModel(day: 1, navigationManager: NavigationManager()))
        #expect(try hostedSnapshot(legacy) != hostedSnapshot(newWeekday(day: 2)))
    }
}
