import DetailInterface
import HomeClientInterface
import HomeInterface
import MVICore
import Navigation

/// 홈 탭. 동작 목록: notes/2026-10-30-R-home-05-main.md (HM3~HM14)
struct HomeMainReducer: Reducer {
    let homeClient: any HomeClient
    let navigator: any Navigator
    let cachedNickname: @MainActor () -> String
    /// 마지막으로 본 애니 id (없으면 0)
    let lastVisitedAnimeId: @MainActor () -> Int
    /// 랭킹 탭으로 (App이 탭을 고른다)
    let showRanking: @MainActor () -> Void
    /// 탐색 탭으로 연도·분기를 넘긴다 (App이 연도·분기를 넘겨 두고 탭을 고른다)
    let showExplore: @MainActor (_ year: Int, _ season: Int) -> Void

    struct State: Equatable {
        var nickname = ""
        var trending: [TrendingAnime] = []
        var recommendations: [HomeAnime] = []
        var referenceTitle: String?
        var weekdayAnimes: [HomeAnime] = []
        var selectedWeekday: WeekdayNewAnimeDay
        var recentReviews: [HomeReview] = []
        var season = 0
        var seasonYear = 0
        var upcoming: [HomeAnime] = []
        var similar: [HomeAnime] = []
        var similarTitle = ""
        var comingSoon: [HomeAnime] = []

        init(selectedWeekday: WeekdayNewAnimeDay) {
            self.selectedWeekday = selectedWeekday
        }

        var hasRecentSimilar: Bool {
            return !similarTitle.isEmpty && !similar.isEmpty
        }
    }

    enum Intent: Sendable {
        case appeared
        case recommendationsLoaded(RecommendationPage)
        case similarLoaded(RecommendationPage?)
        case trendingLoaded([TrendingAnime]?)
        case weekdayLoaded(WeekdayNewAnimeDay, [HomeAnime]?, chained: Bool)
        case recentReviewsLoaded([HomeReview]?)
        case upcomingLoaded(UpcomingSeason?)
        case comingSoonLoaded([HomeAnime]?)
        case weekdaySelected(WeekdayNewAnimeDay)
        case searchTapped
        case animeTapped(animeId: Int?)
        case rankingTapped
        case recommendationsTapped
        case weekdayTapped
        case recentReviewsTapped
        case upcomingTapped
        case similarTapped
        case comingSoonTapped
    }

    func reduce(into state: inout State, intent: Intent) -> Effect<Intent> {
        switch intent {
        case .appeared:
            // 보일 때마다 모든 섹션을 다시 받는다
            state.nickname = cachedNickname()
            let animeId = lastVisitedAnimeId()
            var effects: [Effect<Intent>] = []
            // 레거시: 본 작품이 있으면 결과를 쓰지 않는 비슷한 작품 요청을 한 번 더 보낸다. 없으면 취향 추천을 두 번 보낸다
            if animeId != 0 {
                effects.append(
                    .run { [homeClient] in
                        _ = try? await homeClient.homeRecentRecommendations(animeId: animeId)
                        return nil
                    })
            } else {
                effects.append(fetchRecommendations())
            }
            if animeId == 0 {
                state.similar = []
                state.similarTitle = ""
            } else {
                // 결과가 없으면 비우고, 실패하면 그대로 둔다
                effects.append(
                    .run { [homeClient] in
                        do {
                            return .similarLoaded(
                                try await homeClient.homeRecentRecommendations(animeId: animeId))
                        } catch {
                            return nil
                        }
                    })
            }
            effects.append(fetchRecommendations())
            // 실시간 인기 → 요일별 신작 → 최근 리뷰 → 방영 예정 → 공개 예정 차례로
            effects.append(
                .run { [homeClient] in
                    return .trendingLoaded(try? await homeClient.trending())
                })
            return .merge(effects)

        case .recommendationsLoaded(let page):
            state.recommendations = page.animes
            state.referenceTitle = page.referenceAnimeTitle
            return .none

        case .similarLoaded(let page):
            state.similar = page?.animes ?? []
            state.similarTitle = page?.referenceAnimeTitle ?? ""
            return .none

        case .trendingLoaded(let animes):
            if let animes {
                state.trending = animes
            }
            return fetchWeekday(state.selectedWeekday, chained: true)

        case .weekdayLoaded(let day, let animes, let chained):
            // 응답이 오기 전에 요일이 바뀌었으면 버린다
            if let animes, day == state.selectedWeekday {
                state.weekdayAnimes = animes
            }
            guard chained else {
                return .none
            }
            return .run { [homeClient] in
                return .recentReviewsLoaded(try? await homeClient.homeRecentReviews())
            }

        case .recentReviewsLoaded(let reviews):
            if let reviews {
                state.recentReviews = reviews
            }
            return .run { [homeClient] in
                return .upcomingLoaded(try? await homeClient.upcomingSeason())
            }

        case .upcomingLoaded(let upcoming):
            if let upcoming {
                state.upcoming = upcoming.animes
                state.season = upcoming.season
                state.seasonYear = upcoming.seasonYear
            }
            return .run { [homeClient] in
                return .comingSoonLoaded(try? await homeClient.homeComingSoon())
            }

        case .comingSoonLoaded(let animes):
            if let animes {
                state.comingSoon = animes
            }
            return .none

        case .weekdaySelected(let day):
            guard day != state.selectedWeekday else {
                return .none
            }
            state.selectedWeekday = day
            state.weekdayAnimes = []
            return fetchWeekday(day, chained: false)

        case .searchTapped:
            return push(HomeRoute.search)

        case .animeTapped(let animeId):
            return push(DetailRoute.anime(id: animeId ?? 0))

        case .rankingTapped:
            showRanking()
            return .none

        case .recommendationsTapped:
            return push(HomeRoute.recommendations(animeId: 0, animeTitle: state.referenceTitle))

        case .weekdayTapped:
            return push(HomeRoute.weekdayNewAnime(day: state.selectedWeekday.rawValue))

        case .recentReviewsTapped:
            return push(HomeRoute.recentReviews)

        case .upcomingTapped:
            showExplore(state.seasonYear, state.season)
            return .none

        case .similarTapped:
            return push(HomeRoute.similarRecommendations(animeId: lastVisitedAnimeId()))

        case .comingSoonTapped:
            return push(HomeRoute.comingSoon)
        }
    }

    /// 결과·목록이 없거나 실패하면 그대로 둔다
    private func fetchRecommendations() -> Effect<Intent> {
        return .run { [homeClient] in
            guard let page = try? await homeClient.homeRecommendations() else {
                return nil
            }
            return .recommendationsLoaded(page)
        }
    }

    /// 홈에서는 인기순 6개만
    private func fetchWeekday(_ day: WeekdayNewAnimeDay, chained: Bool) -> Effect<Intent> {
        return .run { [homeClient] in
            let page = try? await homeClient.weekdayNewAnimes(
                day: day.apiValue, sort: WeekdayNewAnimeReducer.Sort.popular.apiValue, lastId: nil,
                size: 6)
            return .weekdayLoaded(day, page?.animes, chained: chained)
        }
    }

    private func push(_ route: some Hashable & Sendable) -> Effect<Intent> {
        return .run { [navigator] in
            await navigator.push(route)
            return nil
        }
    }
}
