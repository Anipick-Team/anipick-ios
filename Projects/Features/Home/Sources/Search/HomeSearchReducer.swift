import Analytics
import DetailInterface
import HomeClientInterface
import MVICore
import Navigation

/// 홈 검색. 동작 목록: notes/2026-10-30-R-home-04-search.md (HS4~HS16)
struct HomeSearchReducer: Reducer {
    let homeClient: any HomeClient
    let navigator: any Navigator
    let analytics: any AnalyticsTracking

    enum Tab: String, CaseIterable, Sendable {
        case animation = "작품"
        case person = "인물"
        case producer = "제작사"
        case initSearch = "인기 작품"

        /// 결과 화면의 하위 탭 (인기 작품 제외)
        static var visibleTabs: [Tab] {
            return allCases.filter { $0 != .initSearch }
        }
    }

    /// 검색 세 가지를 차례로 받는다 (작품 → 인물 → 제작사). 이어 받기는 하나만
    enum Chain: Sendable {
        case all
        case single
    }

    struct State: Equatable {
        var searchText = ""
        var selectedTab = Tab.initSearch
        var popularAnimes: [HomeAnime] = []
        var animes: [SearchAnime] = []
        var persons: [SearchPerson] = []
        var studios: [SearchStudio] = []
        var animeCount = 0
        var personCount = 0
        var studioCount = 0
        var animeLastId: Int?
        var personLastId: Int?
        var studioLastId: Int?
        var recentKeywords: [String] = []
        var isRecentKeywordsShown = false

        func count(of tab: Tab) -> Int {
            switch tab {
            case .animation:
                return animeCount
            case .person:
                return personCount
            case .producer:
                return studioCount
            case .initSearch:
                return 0
            }
        }
    }

    enum Intent: Sendable {
        case appeared
        case popularLoaded([HomeAnime])
        case searchTextChanged(String)
        case clearTapped
        case submitted
        case keywordTapped(String)
        case keywordRemoved(String)
        case clearAllKeywordsTapped
        case tabSelected(Tab)
        case animesLoaded(SearchPage<SearchAnime>?, Chain)
        case animesFailed(any Error, Chain)
        case personsLoaded(SearchPage<SearchPerson>?, Chain)
        case studiosLoaded(SearchPage<SearchStudio>?)
        case animeAppeared(SearchAnime)
        case personAppeared(SearchPerson)
        case studioAppeared(SearchStudio)
        case animeTapped(animeId: Int?)
        case personTapped(SearchPerson)
        case studioTapped(SearchStudio)
        case backTapped
    }

    func reduce(into state: inout State, intent: Intent) -> Effect<Intent> {
        switch intent {
        case .appeared:
            // 보일 때마다 최근 검색어를 읽고 인기 작품을 다시 받는다
            let keywords = homeClient.recentKeywords()
            if keywords.isEmpty {
                state.isRecentKeywordsShown = false
            } else {
                state.isRecentKeywordsShown = true
                state.recentKeywords = keywords
            }
            return .run { [homeClient] in
                guard let animes = try? await homeClient.popularAnimes() else {
                    return nil
                }
                return .popularLoaded(animes)
            }

        case .popularLoaded(let animes):
            state.popularAnimes = animes
            return .none

        case .searchTextChanged(let text):
            state.searchText = text
            if text.isEmpty {
                state.selectedTab = .initSearch
            }
            return .none

        case .clearTapped:
            return reduce(into: &state, intent: .searchTextChanged(""))

        case .submitted:
            clearResults(&state)
            guard !state.searchText.isEmpty else {
                return .none
            }
            // 저장소는 같은 검색어를 앞으로 옮기지만, 화면 목록은 그냥 앞에 넣는다 (레거시 그대로)
            homeClient.saveRecentKeyword(state.searchText)
            state.recentKeywords.insert(state.searchText, at: 0)
            state.isRecentKeywordsShown = true
            state.selectedTab = .animation
            return fetchAnimes(state, .all)

        case .keywordTapped(let keyword):
            clearResults(&state)
            state.searchText = keyword
            state.isRecentKeywordsShown = true
            state.selectedTab = .animation
            return fetchAnimes(state, .all)

        case .keywordRemoved(let keyword):
            state.recentKeywords.removeAll { $0 == keyword }
            homeClient.setRecentKeywords(state.recentKeywords)
            state.isRecentKeywordsShown = !state.recentKeywords.isEmpty
            return .none

        case .clearAllKeywordsTapped:
            homeClient.clearRecentKeywords()
            state.recentKeywords.removeAll()
            state.isRecentKeywordsShown = false
            return .none

        case .tabSelected(let tab):
            state.selectedTab = tab
            return .none

        case .animesLoaded(let page, let chain):
            var effects: [Effect<Intent>] = []
            if let page {
                state.animes += page.items
                state.animeCount = page.count
                state.animeLastId = page.lastId
                if page.lastId == nil {
                    let query = state.searchText
                    effects.append(
                        .run { [analytics] in
                            analytics.log(.search(query: query))
                            return nil
                        })
                }
                let logs = page.items.flatMap { [$0.clickLog, $0.impressionLog].compactMap { $0 } }
                if !logs.isEmpty {
                    effects.append(
                        .run { [homeClient] in
                            for log in logs {
                                await homeClient.sendTrackingLog(log)
                            }
                            return nil
                        })
                }
            } else {
                // 결과가 없으면 인기 작품을 비운다 (레거시 그대로)
                state.popularAnimes = []
            }
            if chain == .all {
                effects.append(fetchPersons(state, .all))
            }
            return .merge(effects)

        case .animesFailed(let error, let chain):
            let log: Effect<Intent> = .run { [analytics] in
                analytics.logError(error, context: "fetchAnimeSearchList")
                return nil
            }
            return chain == .all ? .merge([log, fetchPersons(state, .all)]) : log

        case .personsLoaded(let page, let chain):
            if let page {
                state.persons += page.items
                state.personCount = page.count
                state.personLastId = page.lastId
            }
            return chain == .all ? fetchStudios(state) : .none

        case .studiosLoaded(let page):
            if let page {
                state.studios += page.items
                state.studioCount = page.count
                state.studioLastId = page.lastId
            }
            return .none

        case .animeAppeared(let anime):
            // 마지막 칸이면 받는다 (커서가 없어도 — 그러면 첫 페이지를 다시 받는다)
            return anime == state.animes.last ? fetchAnimes(state, .single) : .none

        case .personAppeared(let person):
            return person == state.persons.last ? fetchPersons(state, .single) : .none

        case .studioAppeared(let studio):
            return studio == state.studios.last ? fetchStudios(state) : .none

        case .animeTapped(let animeId):
            return push(DetailRoute.anime(id: animeId ?? 0))

        case .personTapped(let person):
            return push(DetailRoute.voiceActor(id: person.personId ?? 0))

        case .studioTapped(let studio):
            return push(DetailRoute.producer(id: studio.studioId ?? 0))

        case .backTapped:
            return .run { [navigator] in
                await navigator.pop()
                return nil
            }
        }
    }

    /// 목록만 비운다. 개수·커서는 그대로 둔다 (레거시 `clearAllList`)
    private func clearResults(_ state: inout State) {
        state.animes.removeAll()
        state.persons.removeAll()
        state.studios.removeAll()
    }

    private func fetchAnimes(_ state: State, _ chain: Chain) -> Effect<Intent> {
        let (query, lastId) = (state.searchText, state.animeLastId)
        return .run { [homeClient] in
            do {
                return .animesLoaded(
                    try await homeClient.searchAnimes(query: query, lastId: lastId), chain)
            } catch {
                return .animesFailed(error, chain)
            }
        }
    }

    private func fetchPersons(_ state: State, _ chain: Chain) -> Effect<Intent> {
        let (query, lastId) = (state.searchText, state.personLastId)
        return .run { [homeClient] in
            do {
                return .personsLoaded(
                    try await homeClient.searchPersons(query: query, lastId: lastId), chain)
            } catch {
                // 레거시는 인물 실패를 무시하고 제작사로 넘어간다
                return .personsLoaded(nil, chain)
            }
        }
    }

    private func fetchStudios(_ state: State) -> Effect<Intent> {
        let (query, lastId) = (state.searchText, state.studioLastId)
        return .run { [homeClient] in
            return .studiosLoaded(try? await homeClient.searchStudios(query: query, lastId: lastId))
        }
    }

    private func push(_ route: DetailRoute) -> Effect<Intent> {
        return .run { [navigator] in
            await navigator.push(route)
            return nil
        }
    }
}
