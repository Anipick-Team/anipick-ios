import Analytics
import CommunityClientInterface
import DetailClientInterface
import DetailInterface
import ExploreInterface
import Foundation
import MVICore
import Navigation

/// 애니 상세. 동작 목록: notes/2026-10-30-R-detail-04-anime-info.md (AD3~AD18)
struct AnimeDetailReducer: Reducer {
    let detailClient: any DetailClient
    let communityClient: any CommunityClient
    let navigator: any Navigator
    let analytics: any AnalyticsTracking
    /// 마지막으로 본 애니 저장 (홈의 "비슷한 작품"이 쓴다)
    let setLastVisitedAnimeId: @MainActor (Int) -> Void
    /// 공유 시트 (App: 문구 + Universal Link)
    let shareAnime: @MainActor (_ animeId: Int, _ title: String) -> Void
    let openURL: @MainActor (URL) -> Void

    static let communityInquiryURL = URL(string: "https://forms.gle/zDiFyZnNwm8kFi2A7")!

    enum WatchStatus: String, CaseIterable, Sendable {
        case wantToWatch = "볼 애니"
        case watching = "보는 중"
        case finished = "다 본 애니"
        case empty = ""

        /// 서버 값 (WATCHLIST·WATCHING·FINISHED)
        var status: String {
            switch self {
            case .wantToWatch:
                return "WATCHLIST"
            case .watching:
                return "WATCHING"
            case .finished:
                return "FINISHED"
            case .empty:
                return ""
            }
        }

        init(status: String?) {
            self = Self.allCases.first { $0 != .empty && $0.status == status } ?? .empty
        }
    }

    enum Tab: String, CaseIterable, Sendable {
        case info = "작품 정보"
        case reviews = "리뷰"
        case community = "커뮤니티"
    }

    struct State: Equatable {
        let animeId: Int
        var info: AnimeInfo?
        var averageRating = ""
        var reviewCount = 0
        var isLiked = false
        var watchStatus = WatchStatus.empty
        var cast: [CastMember] = []
        var series: [DetailAnime] = []
        var recommendations: [DetailAnime] = []
        var selectedTab = Tab.info
        var previewImageURL: URL?
        var isCommunityMissingPresented = false
        var isCheckingCommunity = false
        var didStart = false

        init(animeId: Int) {
            self.animeId = animeId
        }

        /// 배너가 없으면 표지, 둘 다 없으면 nil (공백만 있는 주소도 없음으로 본다)
        var bannerURL: URL? {
            return Self.validURL(info?.bannerImageUrl) ?? coverURL
        }

        var coverURL: URL? {
            return Self.validURL(info?.coverImageUrl)
        }

        private static func validURL(_ string: String?) -> URL? {
            guard let trimmed = string?.trimmingCharacters(in: .whitespacesAndNewlines),
                !trimmed.isEmpty
            else {
                return nil
            }
            return URL(string: trimmed)
        }
    }

    enum Intent: Sendable {
        case appeared
        case infoLoaded(AnimeInfo)
        case infoFailed(any Error)
        case castLoaded([CastMember])
        case seriesLoaded([DetailAnime])
        case recommendationsLoaded([DetailAnime])
        case likeTapped
        case likeChanged(Bool)
        case watchStatusTapped(WatchStatus)
        case watchStatusPosted(WatchStatus, code: Int)
        case shareTapped
        case tabSelected(Tab)
        case communityTapped
        case communityChecked(AnimeBoard?)
        case communityCheckFailed
        case communityMissingClosed
        case communityInquiryTapped
        case imageTapped(URL?)
        case previewClosed
        case castHeaderTapped
        case castTapped(CastMember)
        case seriesHeaderTapped
        case recommendationsHeaderTapped
        case animeTapped(animeId: Int?)
        case producerTapped(studioId: Int?)
        case backTapped
    }

    func reduce(into state: inout State, intent: Intent) -> Effect<Intent> {
        switch intent {
        case .appeared:
            // 보일 때마다 마지막으로 본 애니로 저장한다. 내용은 처음 한 번만 받는다 (레거시: ViewModel을 만들 때)
            setLastVisitedAnimeId(state.animeId)
            guard !state.didStart else {
                return .none
            }
            state.didStart = true
            return initialLoads(state.animeId)

        case .infoLoaded(let info):
            state.info = info
            state.averageRating = info.averageRating ?? "-"
            state.reviewCount = info.reviewCount ?? 0
            state.isLiked = info.isLiked ?? false
            state.watchStatus = WatchStatus(status: info.watchStatus)
            let animeId = state.animeId
            return log(.animeDetailView(animeId: animeId, animeTitle: info.title))

        case .infoFailed(let error):
            return .run { [analytics] in
                analytics.logError(error, context: "fetchAnimationInfo")
                return nil
            }

        case .castLoaded(let cast):
            state.cast = cast
            return .none

        case .seriesLoaded(let series):
            state.series = series
            return .none

        case .recommendationsLoaded(let recommendations):
            state.recommendations = recommendations
            return .none

        case .likeTapped:
            // 응답을 받은 뒤 바꾼다 (낙관적이지 않음). 받는 중인지는 보지 않는다
            let (animeId, liked) = (state.animeId, !state.isLiked)
            return .run { [detailClient] in
                guard (try? await detailClient.setAnimeLike(id: animeId, liked: liked)) != nil
                else {
                    return nil
                }
                return .likeChanged(liked)
            }

        case .likeChanged(let liked):
            state.isLiked.toggle()
            let (animeId, title) = (state.animeId, state.info?.title)
            return log(
                liked
                    ? .animeLike(animeId: animeId, animeTitle: title)
                    : .animeUnlike(animeId: animeId, animeTitle: title))

        case .watchStatusTapped(let status):
            if status == state.watchStatus {
                state.watchStatus = .empty
                return deleteWatchStatus(state.animeId)
            }
            state.watchStatus = status
            return postWatchStatus(state.animeId, status)

        case .watchStatusPosted(let status, let code):
            // 128(이미 상태가 있음)이면 지우고 다시 보낸다 (둘을 기다리지 않고 함께 — 레거시 그대로)
            guard code == 128 else {
                return .none
            }
            return .merge([
                deleteWatchStatus(state.animeId), postWatchStatus(state.animeId, status),
            ])

        case .shareTapped:
            guard let info = state.info else {
                return .none
            }
            let title = info.title ?? "애니픽"
            shareAnime(info.animeId, title)
            return log(.animeShare(animeId: info.animeId, animeTitle: title))

        case .tabSelected(let tab):
            state.selectedTab = tab
            return .none

        case .communityTapped:
            guard let info = state.info, !state.isCheckingCommunity else {
                return .none
            }
            state.isCheckingCommunity = true
            return .run { [communityClient] in
                do {
                    return .communityChecked(try await communityClient.board(animeId: info.animeId))
                } catch {
                    return .communityCheckFailed
                }
            }

        case .communityChecked(let board):
            state.isCheckingCommunity = false
            guard let info = state.info, let board, board.hasBoard == true,
                let seriesId = board.seriesId
            else {
                state.isCommunityMissingPresented = true
                return .none
            }
            let genres = board.genres ?? []
            let route = ExploreRoute.communityBoard(
                seriesId: seriesId, animeTitle: board.title ?? info.title ?? "애니메이션",
                coverImageUrl: board.coverImageUrl ?? info.coverImageUrl,
                genreNames: genres.isEmpty ? (info.genres ?? []) : genres)
            return push(route)

        case .communityCheckFailed:
            state.isCheckingCommunity = false
            return .none

        case .communityMissingClosed:
            state.isCommunityMissingPresented = false
            return .none

        case .communityInquiryTapped:
            state.isCommunityMissingPresented = false
            openURL(Self.communityInquiryURL)
            return .none

        case .imageTapped(let url):
            state.previewImageURL = url
            return .none

        case .previewClosed:
            state.previewImageURL = nil
            return .none

        case .castHeaderTapped:
            return push(DetailRoute.cast(animeId: state.info?.animeId ?? state.animeId))

        case .castTapped(let member):
            return push(DetailRoute.voiceActor(id: member.voiceActor?.id ?? 0))

        case .seriesHeaderTapped:
            return push(
                DetailRoute.series(
                    animeId: state.info?.animeId ?? state.animeId,
                    animeTitle: state.info?.title ?? "-"))

        case .recommendationsHeaderTapped:
            return push(
                DetailRoute.recommendations(
                    animeId: state.info?.animeId ?? state.animeId,
                    animeTitle: state.info?.title ?? "-"))

        case .animeTapped(let animeId):
            return push(DetailRoute.anime(id: animeId ?? 0))

        case .producerTapped(let studioId):
            return push(DetailRoute.producer(id: studioId ?? 0))

        case .backTapped:
            return .run { [navigator] in
                await navigator.pop()
                return nil
            }
        }
    }

    /// 레거시 ViewModel init의 요청들. 관련 작품 목록(series, size 10) 결과는 화면에서 쓰지 않는다
    private func initialLoads(_ animeId: Int) -> Effect<Intent> {
        return .merge([
            .run { [detailClient] in
                do {
                    return .infoLoaded(try await detailClient.animeInfo(id: animeId))
                } catch {
                    return .infoFailed(error)
                }
            },
            .run { [detailClient] in
                _ = try? await detailClient.series(animeId: animeId, lastId: nil)
                return nil
            },
            .run { [detailClient] in
                guard let cast = try? await detailClient.detailCast(animeId: animeId) else {
                    return nil
                }
                return .castLoaded(cast)
            },
            .run { [detailClient] in
                guard let series = try? await detailClient.detailSeries(animeId: animeId) else {
                    return nil
                }
                return .seriesLoaded(series)
            },
            .run { [detailClient] in
                guard let animes = try? await detailClient.detailRecommendations(animeId: animeId)
                else {
                    return nil
                }
                return .recommendationsLoaded(animes)
            },
        ])
    }

    private func postWatchStatus(_ animeId: Int, _ status: WatchStatus) -> Effect<Intent> {
        return .run { [detailClient] in
            guard
                let code = try? await detailClient.setWatchStatus(
                    animeId: animeId, status: status.status)
            else {
                return nil
            }
            return .watchStatusPosted(status, code: code)
        }
    }

    private func deleteWatchStatus(_ animeId: Int) -> Effect<Intent> {
        return .run { [detailClient] in
            try? await detailClient.deleteWatchStatus(animeId: animeId)
            return nil
        }
    }

    private func log(_ event: AnalyticsEvent) -> Effect<Intent> {
        return .run { [analytics] in
            analytics.log(event)
            return nil
        }
    }

    private func push(_ route: some Hashable & Sendable) -> Effect<Intent> {
        return .run { [navigator] in
            await navigator.push(route)
            return nil
        }
    }
}
