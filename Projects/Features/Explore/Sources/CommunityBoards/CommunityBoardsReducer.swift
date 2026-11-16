import CommunityClientInterface
import ExploreInterface
import MVICore
import Navigation

/// 탐색 탭 "커뮤니티": 애니 게시판 목록. 동작 목록: notes/2026-10-30-R-explore-01-community-boards.md (CB1~CB10)
struct CommunityBoardsReducer: Reducer {
    static let sortOptions = ["인기순", "최신순"]

    let communityClient: any CommunityClient
    let navigator: any Navigator
    /// 검색어를 바꾼 뒤 요청까지 (레거시 0.35초)
    var searchDelay: Duration = .milliseconds(350)

    struct Item: Hashable, Sendable {
        let board: CommunityBoard

        var title: String {
            return board.title ?? "제목 없음"
        }

        /// 첫 장르, 없으면 "커뮤니티"
        var tag: String {
            return board.genres.first ?? "커뮤니티"
        }
    }

    struct State: Equatable {
        var items: [Item] = []
        var isLoading = false
        var errorMessage: String?
        var lastId: Int?
        var lastValue: String?
        var hasNextPage = true
        var searchText = ""
        var keyword = ""
        var sort = "popular"
        var sortTitle = "인기순"
        var isSortMenuPresented = false
    }

    enum Intent: Sendable {
        case appeared
        case searchTextChanged(String)
        case searchDelayElapsed
        case clearSearchTapped
        case itemAppeared(Item)
        case pageLoaded(CommunityBoardPage, reset: Bool)
        case loadFailed
        case retryTapped
        case sortButtonTapped
        case sortSelected(String)
        case backgroundTapped
        case itemTapped(Item)
    }

    func reduce(into state: inout State, intent: Intent) -> Effect<Intent> {
        switch intent {
        case .appeared, .retryTapped, .searchDelayElapsed:
            return fetch(&state, reset: true)

        case .searchTextChanged(let text):
            // 바꿀 때마다 0.35초 뒤 처음부터 받는다. 이전 대기를 취소하지 않는다 (레거시 그대로, CB3)
            state.searchText = text
            state.keyword = text.trimmingCharacters(in: .whitespacesAndNewlines)
            return .run { [searchDelay] in
                try? await Task.sleep(for: searchDelay)
                return .searchDelayElapsed
            }

        case .clearSearchTapped:
            return reduce(into: &state, intent: .searchTextChanged(""))

        case .itemAppeared(let item):
            guard item.board.seriesId == state.items.last?.board.seriesId else {
                return .none
            }
            return fetch(&state, reset: false)

        case .pageLoaded(let page, let reset):
            let items = page.boards.map(Item.init)
            state.items = reset ? items : state.items + items
            state.lastId = page.lastId
            state.lastValue = page.lastValue
            state.hasNextPage = !items.isEmpty && page.lastId != nil
            state.isLoading = false
            return .none

        case .loadFailed:
            state.isLoading = false
            state.errorMessage = "커뮤니티 게시판을 불러오지 못했습니다."
            return .none

        case .sortButtonTapped:
            state.isSortMenuPresented.toggle()
            return .none

        case .sortSelected(let title):
            state.sortTitle = title
            state.isSortMenuPresented = false
            state.sort = title == "인기순" ? "popular" : "latest"
            return fetch(&state, reset: true)

        case .backgroundTapped:
            state.isSortMenuPresented = false
            return .none

        case .itemTapped(let item):
            let board = item.board
            return .run { [navigator] in
                await navigator.push(
                    ExploreRoute.communityBoard(
                        seriesId: board.seriesId, animeTitle: item.title,
                        coverImageUrl: board.coverImageUrl, genreNames: board.genres))
                return nil
            }
        }
    }

    /// 레거시 `fetch(reset:)`: 받는 중이거나 (처음부터가 아니고) 다음 페이지가 없으면 요청하지 않는다
    private func fetch(_ state: inout State, reset: Bool) -> Effect<Intent> {
        guard !state.isLoading, reset || state.hasNextPage else {
            return .none
        }
        if reset {
            state.lastId = nil
            state.lastValue = nil
            state.hasNextPage = true
        }
        state.isLoading = true
        state.errorMessage = nil
        let (sort, keyword, lastValue, lastId) = (
            state.sort, state.keyword.isEmpty ? nil : state.keyword, state.lastValue, state.lastId
        )
        return .run { [communityClient] in
            guard
                let page = try? await communityClient.exploreBoards(
                    sort: sort, keyword: keyword, lastValue: lastValue, lastId: lastId)
            else {
                return .loadFailed
            }
            return .pageLoaded(page, reset: reset)
        }
    }
}
