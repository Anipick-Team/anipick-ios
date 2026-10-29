//
//  AppEntryView.swift
//  AniPick
//
//  Created by cho on 6/22/25.
//

import DetailInterface
import HomeInterface
import MyInfoInterface
import ReviewInterface
import SwiftUI
import SettingInterface
import Utils

struct AppEntryView: View {
    @EnvironmentObject var navigationManager: NavigationManager
    @StateObject var viewModel = AppEntryViewModel()
    var body: some View {
        NavigationStack(path: $navigationManager.path) {
            Group {
                if navigationManager.isLoggedIn {
                    AppDIContainer.makeContentView(activeTab: .home)
                } else {
                    AppDIContainer.makeLoginView()
                        .onAppear { AnalyticsManager.logScreen("login") }
                }
            }
            .background(Color.white)
            .onChange(of: navigationManager.isLoggedIn) { newValue in
                DLog("🔐 [Login] AppEntryView 루트 전환 - isLoggedIn=\(newValue) → \(newValue ? "홈" : "로그인") 화면")
            }
            .onAppear {
                viewModel.fetchMataData()
                viewModel.checkVersion()
            }
            // 새 Feature가 push한 Route의 목적지. 탭 루트에서 한 번만 등록한다 (A2)
            .navigationDestination(for: SettingRoute.self) { route in
                AppDIContainer.settingBuilder.make(route)
                    .onAppear { AnalyticsManager.logScreen(route.screenName) }
            }
            // 아직 레거시인 화면: 이관한 Feature가 push한 Route를 레거시 화면에 연결한다
            .navigationDestination(for: DetailRoute.self) { route in
                switch route {
                case .anime(let id):
                    AppDIContainer.makeAnimeDetailView(animeId: id)
                        .onAppear { AnalyticsManager.logScreen(route.screenName) }
                case .voiceActor(let id):
                    AppDIContainer.makeVoiceActorDetailView(animeId: id)
                        .onAppear { AnalyticsManager.logScreen(route.screenName) }
                }
            }
            .navigationDestination(for: HomeRoute.self) { route in
                switch route {
                case .search:
                    AppDIContainer.makeHomeSearchView()
                        .onAppear { AnalyticsManager.logScreen(route.screenName) }
                }
            }
            .navigationDestination(for: MyInfoRoute.self) { route in
                AppDIContainer.myInfoBuilder.make(route)
                    .onAppear { AnalyticsManager.logScreen(route.screenName) }
            }
            .navigationDestination(for: ReviewRoute.self) { route in
                AppDIContainer.reviewBuilder.make(route)
                    .onAppear { AnalyticsManager.logScreen(route.screenName) }
            }
            .navigationDestination(for: AppRoute.self) { route in
                Group {
                    switch route {
                    case .emailSignup:
                        AppDIContainer.makeEmailSignupView()
                    case .emailLogin:
                        AppDIContainer.makeEmailLoginView()
                    case .LoginProblem:
                        LoginProblemView()
                    case .findPassword:
                        AppDIContainer.makeFindPasswordView()
                    case .homeSearch:
                        AppDIContainer.makeHomeSearchView()
                    case .homeView:
                        AppDIContainer.makeHomeView()
                    case .editNickname:
                        AppDIContainer.settingBuilder.make(.editNickname)
                    case .editEmail:
                        AppDIContainer.settingBuilder.make(.editEmail)
                    case .editPassword:
                        AppDIContainer.settingBuilder.make(.editPassword)
                    case .deleteAccount:
                        AppDIContainer.settingBuilder.make(.withdrawal)
                    case .myInfoInToWatchList:
                        AppDIContainer.myInfoBuilder.make(.watchList)
                    case .myInfo:
                        AppDIContainer.makeMyInfoView()
                    case .myInfoWatchingList:
                        AppDIContainer.myInfoBuilder.make(.watching)
                    case .finishedWatchList:
                        AppDIContainer.myInfoBuilder.make(.finished)
                    case .likeAnimeList:
                        AppDIContainer.myInfoBuilder.make(.likedAnimes)
                    case .likePersonList:
                        AppDIContainer.myInfoBuilder.make(.likedPersons)
                    case .ratedAnimeList:
                        AppDIContainer.makeMyInfoRatedAnimeView()
                    case .myContent:
                        MyContentView()
                    case .ranking:
                        AppDIContainer.rankingBuilder.make(.main)
                    case .research:
                        AppDIContainer.makeResearchView()
                    case .review(let starRating, let animeId, let reviewContent):
                        AppDIContainer.reviewBuilder.make(
                            .write(animeId: animeId, rating: starRating, content: reviewContent)
                        )
                    case .explore(let season, let seaseonYear):
                        AppDIContainer.makeExploreView(season: season, year: seaseonYear)
                    case .animeDetail(let animeId):
                        AppDIContainer.makeAnimeDetailView(animeId: animeId)
                    case .resetPassword:
                        AppDIContainer.makeResetPassword()
                    case .content(let activeTab):
                        AppDIContainer.makeContentView(activeTab: activeTab)
                    case .adultSetting:
                        AppDIContainer.makeAdultSettingView()
                    case .adultCheck:
                        // TODO: 성인인증 화면 구현 시 연결
                        AppDIContainer.makeAdultSettingView()
                    case .setting:
                        AppDIContainer.settingBuilder.make(.main)
                    case .inquiry:
                        InquiryView()
                    case .preferenceSelection:
                        AppDIContainer.makePreferenceSelectionView()
                    case .comingSoonDetail:
                        AppDIContainer.makeComingSoonView()
                    case .weekdayNewAnime(let day):
                        AppDIContainer.makeWeekdayNewAnimeView(day: day)
                    case .mainLoginView:
                        AppDIContainer.makeLoginView()
                    case .recentReview:
                        AppDIContainer.makeRecentReviewView()
                    case .recommendView(let animeId):
                        AppDIContainer.makeRecommendationView(animeId: animeId)
                    case let .community(seriesId, animeTitle, coverImageUrl, genreNames):
                        CommunityView(
                            seriesId: seriesId,
                            animeTitle: animeTitle,
                            coverImageUrl: coverImageUrl,
                            genreNames: genreNames
                        )
                    case let .communityDetail(postId):
                        CommunityDetailView(postId: postId)
                    case let .communityWrite(seriesId, animeTitle):
                        CommunityWriteView(seriesId: seriesId, animeTitle: animeTitle)
                    case let .communityEdit(postId, seriesId, animeTitle, title, content, isSpoiler, imageIds):
                        CommunityWriteView(
                            seriesId: seriesId,
                            animeTitle: animeTitle,
                            postId: postId,
                            initialTitle: title,
                            initialContent: content,
                            initialIsSpoiler: isSpoiler,
                            initialImageIds: imageIds
                        )
                    case .producerDetail(let studioId):
                        AppDIContainer.makeProducerDetailView(studioId: studioId)
                    case .voiceActorDetail(let animeId):
                        AppDIContainer.makeVoiceActorDetailView(animeId: animeId)
                    case .characterAndVoiceActorDetail(let animeId):
                        AppDIContainer.makeCharacterAndVoiceActorDetailVIew(animeId: animeId)
                    case let .seriesDetail(animeId, animeTitle):
                        AppDIContainer.makeSeriesDetialView(animeId: animeId, animeTitle: animeTitle)
                    
                    case let .recommend(animeId, animeTitle):
                        AppDIContainer.makeRecommendView(animeId: animeId, animeTitle: animeTitle)
                    case let .recommend2(animeId, animeTitle):
                        AppDIContainer.makeRecommemnd2View(animeId: animeId, animeTitle: animeTitle)
                    default:
                        Text("asdfasdf")
                    }
                }
                .onAppear {
                    if let screenName = route.screenName {
                        AnalyticsManager.logScreen(screenName)
                    }
                }
            }
        }
        .background(Color.white)
        .sheet(item: $navigationManager.presentedRoute) { presented in
            modalDestination(presented.route)
        }
    }
}

extension AppEntryView {
    /// 새 Feature가 present한 Route의 목적지. 처음 모달 Route가 생기는 이관 반복에서 case를 추가한다.
    @ViewBuilder
    private func modalDestination(_ route: AnyHashable) -> some View {
        let _ = assertionFailure("모달 목적지가 등록되지 않은 Route: \(route)")
        EmptyView()
    }
}

