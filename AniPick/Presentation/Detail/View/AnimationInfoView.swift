//
//  AnimationInfoView.swift
//  AniPick
//
//  Created by cho on 5/25/25.
//

import SwiftUI
import PopupView

struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}



struct AnimationInfoView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject var viewModel: AnimationInfoViewModel
    @State private var starRating: Double = 0.0
    @State private var selectedAnimationStatusTab: AnimationWatchStatus = .empty
    @State private var selectedInfoTab: AnimationInfoTab = .animationInfo
  //  @State private var selectedSortOption: SortOption = .latest
    
    @State private var isPresentBlockUserPopupView: Bool = false
    @State private var isPresentReportView: Bool = false
    @State private var isPresentReportReasonView: Bool = false
    @State private var selectedReviewId: Int? = nil
    @State private var selectedUserId: Int? = nil
    
    @State private var headerCollapsed: Bool = false
    
    @State private var scrollOffset: CGFloat = 0
    @State private var menuFrame2: CGRect = .zero
    
    @State private var isShowToastReportReview: Bool = false
    @State private var isShowToastBlockUser: Bool = false
    @State private var isPresentMyReviewPopupView: Bool = false
    @State private var isShowBlockPopupView: Bool = false
    @State private var selectedPopupItemReviewId: Int = 0
    @State private var selectedBlockUserId: Int = 0
    

    
    var body: some View {
        ZStack {
            EnableSwipeBackGesture()
                  .frame(width: 0, height: 0)
            
            ScrollView(showsIndicators: false) {
                GeometryReader { geo in
                    Color.clear
                        .onChange(of: geo.frame(in: .global).minY) { newValue in
                            DLog("🌀 스크롤 offset 변경됨: \(newValue)")
                            self.scrollOffset = newValue
                            self.isPresentMyReviewPopupView = false
                            self.isShowBlockPopupView = false
//                            if self.isShowBlockPopupView {
//                                self.isShowBlockPopupView = false
//                            }
                        }
                        .preference(key: ScrollOffsetKey.self,
                                    value: geo.frame(in: .global).minY)
                }
                .frame(height: 0)
                VStack(spacing: 0) {
                    GeometryReader { geo in
                        let minY = geo.frame(in: .global).minY
                        
                        ZStack(alignment: .top) {
                            if let bannerUrl = viewModel.animeDetailInfo?.bannerImageUrl {
                                ZStack {
                                    AsyncImage(url: URL(string: bannerUrl)) { phase in
                                        switch phase {
                                        case .empty:
                                            Image(.animeThumbnail)
                                                .resizable()
                                                .frame(maxWidth: .infinity)
                                                .frame(height: 280)
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: UIScreen.main.bounds.width, height: 280)
                                                .clipped()
                                        case .failure:
                                            Image(.animeThumbnail)
                                                .resizable()
                                                .frame(maxWidth: .infinity)
                                                .frame(height: 280)
                                            
                                        @unknown default:
                                            EmptyView()
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 280)
                                    .ignoresSafeArea(edges: .top)
                                    
                                    Color.black.opacity(0.4)
                                        .frame(width: UIScreen.main.bounds.width, height: 280)
                                }
                                
                            } else {
                                Image(.emptyBackgroundImg)
                                    .resizable()
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 280)
                                    .ignoresSafeArea(edges: .top)
                            }
                            
                            HStack(alignment: .top, spacing: 0) {
                                ZStack {
                                    HStack(alignment: .center, spacing: 0) {
                                        Button {
                                            dismiss()
                                            DLog("뒤로가기 누름")
                                        } label: {
                                            Image("chevron-left-stroke")
                                                .resizable()
                                                .frame(width: 24, height: 24)
                                        }
                                        .padding(.leading, 20)
                                        Spacer()
                                    }
                                    
                                    Spacer()
                                    
                                }
                               // .zIndex(2)
                                .padding(.top, 54)
                                
                                VStack(alignment: .leading, spacing: 0) {
                                    Spacer()
                                    
                                    if let url = viewModel.animeDetailInfo?.coverImageUrl {
                                        AsyncImage(url: URL(string: url)) { phase in
                                            switch phase {
                                            case .empty:
                                                Image(.animeThumbnail)
                                                    .resizable()
                                                    .frame(width: 133, height: 154)
                                                    .padding(.bottom, 23)
                                                    .padding(.trailing, 20)
                                                    .cornerRadius(8)
                                            case .success(let image):
                                                image
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: 133, height: 154)
                                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3), lineWidth: 1))
                                                    .padding(.bottom, 23)
                                                    .padding(.trailing, 20)
                                                
                                            case .failure:
                                                Image(.animeThumbnail)
                                                    .resizable()
                                                    .frame(width: 133, height: 154)
                                                    .padding(.bottom, 23)
                                                    .padding(.trailing, 20)
                                                    .cornerRadius(8)
                                            @unknown default:
                                                EmptyView()
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, self.selectedInfoTab == .reviewInfo ? -10 : 0)
                        }
                        .ignoresSafeArea(edges: .top)
                        .padding(.bottom, 25)
                        .onChange(of: minY) { newValue in
                                self.headerCollapsed = newValue < -120   // 임계값 조정 가능
                        }
                    }
                   
                    .frame(height: 280)
                    
                    if let detailInfo = viewModel.animeDetailInfo {
                        VStack(alignment: .leading, spacing: 0) {
                            HStack(alignment: .center, spacing: 0) {
                                Text(detailInfo.title ?? "--")
                                    .customFontStyle(size: 20, color: .anipickBlack, weight: .semibold)
                                    .padding(.trailing, 12)
                                
                                // TODO: 눌렀을 때 좋아요 처리해야함
                                Button {
                                    if self.viewModel.isActiveLike { // 이미 좋아요한 상태
                                        self.viewModel.tappedAnimeDislike()
                                    } else {
                                        self.viewModel.tappedAnimeLike()
                                    }
                                } label: {
                                    Image(self.viewModel.isActiveLike ? .fillHeartGreen : .unfilledHeart)
                                        .resizable()
                                        .frame(width: 19, height: 19)
                                }
                                
                                Spacer()
                                
                                Button {
                                    DLog("공유버튼 탭탭")
                                } label: {
                                    Image(.shareButton)
                                }
                            }
                            .padding(.bottom, 8)
                            .padding(.top, 8)
                            
                            HStack(alignment: .center, spacing: 0) {
                                Image(.fillPickStar)
                                    .resizable()
                                    .frame(width: 18, height: 18)
                                
                                Text(viewModel.averageRating)
                                    .customFontStyle(size: 14, color: .point, weight: .semibold)
                                    .padding(.leading, 8)
                                    .lineLimit(1)
                                    .fixedSize()
                            }
                            
                            Spacer().frame(height: 32)
                            
                            HStack(alignment: .center, spacing: 0) {
                                animationWatchState(animeId: detailInfo.animeId, title: .wantToWatch)
                                animationWatchState(animeId: detailInfo.animeId, title: .watching)
                                animationWatchState(animeId: detailInfo.animeId, title: .finished)
                            }
                            .frame(maxWidth: .infinity)
                            
                            Spacer().frame(height: 23)
                            
                            Rectangle()
                                .frame(height: 3)
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal, -40)
                                .foregroundStyle(.gray5)
                            
                            Spacer().frame(height: 20)
                            
                            HStack(alignment: .center, spacing: 0) {
                                selectedTab(title: .animationInfo)
                                selectedTab(title: .reviewInfo, animationCount: viewModel.reviewCount)
                                selectedTab(title: .community) {
                                    viewModel.moveToCommunityView()
                                }
                            }
                            .padding(.bottom, 13)

                            switch self.selectedInfoTab {
                            case .animationInfo:
                                AnimationDetailInfoView(
                                    detailInfo: detailInfo,
                                    seriesInfo: viewModel.seriesAnimeInfo,
                                    recommendationInfo: viewModel.recommendationInfo,
                                    viewModel: viewModel
                                )
                            case .reviewInfo:
                                ReviewDetailInfoView(
                                    viewModel: viewModel,
                                    scrollOffset: self.$scrollOffset,
                                    isShowOnlyReview: self.$viewModel.isShowOnlyReview,
                                    isShowSortOptionView: self.$viewModel.isShowSortOptionView,
                                    starRating: self.$starRating
                                ) { id, frame in
                                    self.menuFrame2 = frame
                                    self.isPresentMyReviewPopupView.toggle()
                                } onMoreButtonTapped: { reviewId, blockUserId, frame in
                                    self.menuFrame2 = frame
                                    self.isShowBlockPopupView.toggle()
                                    self.selectedPopupItemReviewId = reviewId
                                    self.selectedBlockUserId = blockUserId
                                }
                            case .community:
                                EmptyView()
                            }

                            Spacer().frame(height: 30)
                            
                        }
                        .padding(.horizontal, self.selectedInfoTab == .reviewInfo ? 10 : 20)
                    }
                }
            }
            .onPreferenceChange(ScrollOffsetKey.self) { value in
                DLog("ScrollVIew 😀 - \(value)")
                self.scrollOffset = value
            }
            // popup
            if self.isPresentBlockUserPopupView {
                BlockUserPopupView {
                    // cancel tapped
                    DLog("block user cancel tapped")
                    self.isPresentBlockUserPopupView.toggle()
                } okAction: {
                    DLog("block user action tapped")
                    self.isPresentBlockUserPopupView.toggle()
                    self.viewModel.postBlockUser(userId: self.selectedUserId ?? 0) {
                        self.isShowToastBlockUser.toggle()
                        self.viewModel.fetchReview()
                    }
                }
            }
            
            if self.isPresentReportView {
                ReportReviewPopupView {
                    // cancel Action
                    DLog("Report Popup Cancel Tapped")
                    self.isPresentReportView.toggle()
                } okAction: {
                    // 다음 action
                    DLog("next popup tapped")
                    self.isPresentReportView.toggle()
                    self.isPresentReportReasonView.toggle()
                }
            }
            
            if self.isPresentReportReasonView {
                ReportReviewWithReasonPopupView {
                    // cancel Tapped
                    DLog("report reason popup cancel")
                    self.isPresentReportReasonView.toggle()
                } okAction: { reason in
                    DLog("report reason - \(reason)")
                    self.isPresentReportReasonView.toggle()
                    self.viewModel.postReportReivew(
                        id: self.selectedReviewId ?? 0,
                        message: reason
                    ) { 
                        self.isShowToastReportReview.toggle()
                        self.viewModel.fetchReview()
                    }
                }
            }
            
            if self.isPresentMyReviewPopupView {
                MyReviewPopupView(
                    isShowBlockMenu: self.$isPresentMyReviewPopupView) {
                        // 삭제 이벤트
                        DLog("삭제삭제")
                        self.isPresentMyReviewPopupView.toggle()
                        self.viewModel.deleteMyReview(reviewId: viewModel.MyReview?.reviewId ?? 0) {
                            self.viewModel.fetchReview()
                            self.viewModel.getMyReview()
                        }
                    } editAction: {
                        DLog("수정수정")
                        self.isPresentMyReviewPopupView.toggle()
                        self.viewModel.moveToRewriteReview()
                    }
                    .position(x: UIScreen.main.bounds.width - 70, y: self.menuFrame2.maxY + 60)
                    .zIndex(1000)
            }
            
            if self.isShowBlockPopupView {
                ReportBlockMenuPopup(
                    isShowBlockMenu: self.$isShowBlockPopupView) {
                        // 신고 버튼 Tapped
                        DLog("신고버튼 tapped")
                        self.isShowBlockPopupView.toggle()
                        NotificationCenter.default.post(
                            name: .presentReportPopup,
                            object: nil,
                            userInfo: ["reviewId": self.selectedPopupItemReviewId]
                        )
                    } blockAction: {
                        // 차단 버튼 Tapped
                        DLog("차단버튼 tapped")
                        self.isShowBlockPopupView.toggle()
                        NotificationCenter.default.post(
                            name: .presentBlockUserPopup,
                            object: nil,
                            userInfo: ["userId": self.selectedBlockUserId]
                        )
                    }
                    .position(x: UIScreen.main.bounds.width - 70, y: self.menuFrame2.maxY + 60)
                    .zIndex(1000)
            }
        }
        .overlay(alignment: .top) {
            if headerCollapsed {
                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        Button {
                            dismiss()
                        } label: {
                            Image("chevron-left-stroke")
                                .resizable()
                                .frame(width: 24, height: 24)
                        }
                        
                        Spacer()
                        
                        Text(viewModel.animeDetailInfo?.title ?? "--")
                            .customFontStyle(size: 18, color: .anipickBlack, weight: .semibold)
                            .lineLimit(1)
                            .padding(.leading, 12)
                            .padding(.trailing, 8)
                        
                        Button {
                            if self.viewModel.isActiveLike { // 이미 좋아요한 상태
                                self.viewModel.tappedAnimeDislike()
                            } else {
                                self.viewModel.tappedAnimeLike()
                            }
                        } label: {
                            Image(self.viewModel.isActiveLike ? .fillHeartGreen : .unfilledHeart)
                                .resizable()
                                .frame(width: 19, height: 19)
                        }
                        
                        Spacer()
                    }
                    .padding(.bottom, 12)

                    
                    HStack(alignment: .center, spacing: 0) {
                        selectedTab(title: .animationInfo)
                        selectedTab(title: .reviewInfo, animationCount: viewModel.reviewCount)
                        selectedTab(title: .community) {
                            viewModel.moveToCommunityView()
                        }
                    }
                    .padding(.bottom, 13)
                }
                .padding(.top, UIApplication.shared.windows.first?.safeAreaInsets.top ?? 20)
                .padding(.bottom, 12)
                .padding(.horizontal, 20)
                .transition(.opacity.combined(with: .move(edge: .top)))
                .background(Color.white)
                
            }
                
        }
     //   .animation(.easeInOut(duration: 0.22), value: headerCollapsed)
        .background(Color.white)
        .edgesIgnoringSafeArea(.top)
        .onAppear {
            viewModel.setLastVisitedAnimeId()
        }
        .onDisappear {
            self.isShowToastBlockUser = false
            self.isShowToastReportReview = false
        }
        .onReceive(NotificationCenter.default.publisher(for: .presentReportPopup)) { notification in
            if let info = notification.userInfo,
               let reviewId = info["reviewId"] as? Int {
                self.selectedReviewId = reviewId
                self.isPresentReportView.toggle()
            }
            
        }
        .onReceive(NotificationCenter.default.publisher(for: .presentBlockUserPopup)) { notification in
            DLog("block user tapped")
            if let info = notification.userInfo,
               let userId = info["userId"] as? Int {
                self.selectedUserId = userId
                self.isPresentBlockUserPopupView.toggle()
            }
            
        }
        .navigationBarBackButtonHidden()
        .popup(isPresented: self.$isShowToastBlockUser) {
            Text("사용자 차단이 완료되었습니다.")
                .customFontStyle(size: 14, color: .gray5)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.anipickBlack)
                .cornerRadius(8)
                .padding(.horizontal, 20)
        } customize: {
            $0
                .type(.floater())
                .position(.top)
                .autohideIn(2)
        }
        .popup(isPresented: self.$isShowToastReportReview) {
            Text("신고가 정상적으로 접수되었습니다.")
                .customFontStyle(size: 14, color: .gray5)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.anipickBlack)
                .cornerRadius(8)
                .padding(.horizontal, 20)
        } customize: {
            $0
                .type(.floater())
                .position(.top)
                .autohideIn(2)
        }
    }
        
    private func animationWatchState(animeId: Int, title: AnimationWatchStatus) -> some View {
        Button {
            DLog("\(title.title) 탭탭")
            if self.viewModel.selectedAnimationStatusTab == title {
                self.viewModel.selectedAnimationStatusTab = .empty
                self.viewModel.deleteAnimeWatchingStatus(animeId: animeId)
            } else {
                self.viewModel.selectedAnimationStatusTab = title
                self.viewModel.postAnimeWatchingStatus(animeId: animeId, status: title.status)
            }
            
        } label: {
            Text(title.title)
                .customFontStyle(size: 14, color: title == self.viewModel.selectedAnimationStatusTab ? .white : .anipickBlack)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(title == self.viewModel.selectedAnimationStatusTab ? .anipickPrimary : .gray5)
                .cornerRadius(8)
        }
        .padding(.horizontal, 2)
    }
    
    private func selectedTab(title: AnimationInfoTab, animationCount: Int = 0, action: (() -> Void)? = nil) -> some View {
        VStack(alignment: .leading, spacing: 0) {
                Button {
                    DLog("\(title.title) 탭탭")
                    if let action {
                        action()
                    } else {
                        self.selectedInfoTab = title
                    }
                } label: {
                    if title.title == "리뷰" {
                        Text("\(title.title)(\(animationCount)개)")
                            .customFontStyle(size: 14, color: title == self.selectedInfoTab ? .anipickBlack : .gray6)
                            .padding(.bottom, 8)
                    } else {
                        Text(title.title)
                            .customFontStyle(size: 14, color: title == self.selectedInfoTab ? .anipickBlack : .gray6)
                            .padding(.bottom, 8)
                    }
                }
                .frame(maxWidth: .infinity)
            
            if title == self.selectedInfoTab {
                Rectangle()
                    .frame(height: 2)
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(.gray5) // 선택된 탭 표시 색상
            } else {
                Color.clear.frame(height: 2)
            }
        }
    }
}


struct CharacterVoiceActorCell: View {
    var characterName: String
    var actorName: String
    var characterImage: Image = Image(systemName: "person.fill") // 예시용 이미지
    var actorImage: Image = Image(systemName: "person.fill")     // 예시용 이미지

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                // 캐릭터 이미지
                characterImage
                    .resizable()
                    .scaledToFill()
                    .frame(width: 91, height: 95)
                    .background(Color.gray.opacity(0.3))
                    .clipped()
                
                Rectangle()
                       .fill(Color.gray7)
                       .frame(width: 8)

                // 성우 이미지
                actorImage
                    .resizable()
                    .scaledToFill()
                    .frame(width: 91, height: 95)
                    .background(Color.gray.opacity(0.3))
                    .clipped()
            }
            .frame(width: 190)

            HStack(spacing: 0) {
                Text(characterName)
                    .customFontStyle(size: 14, color: .anipickBlack)
                    .frame(maxWidth: .infinity)

                Text(actorName)
                    .customFontStyle(size: 14, color: .anipickBlack)
                    .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 8)
            .background(Color(red: 248/255, green: 249/255, blue: 253/255)) // 연한 회색
        }
        .background(Color.white)
        .frame(width: 190)
        .cornerRadius(16)
        .clipped()
    }
}


enum AnimationDetailInfo: String, CaseIterable {
    case type = "타입"
    case gerne = "장르"
    case release = "방영 시기"
    case episode = "에피소드"
    case ageRating = "연령 등급"
    case productionCompany = "제작사"
    
    var title: String { self.rawValue }
}

enum AnimationWatchStatus: String, CaseIterable {
    case wantToWatch = "볼 애니"
    case watching = "보는 중"
    case finished = "다 본 애니"
    case empty = ""
    
    var title: String { self.rawValue }
    
    var status: String {
        switch self {
        case .wantToWatch:
            "WATCHLIST"
        case .watching:
            "WATCHING"
        case .finished:
            "FINISHED"
        case .empty:
            ""
        }
    }
    
    static func fromStatus(_ status: String) -> AnimationWatchStatus? {
            switch status {
            case "WATCHLIST":
                return .wantToWatch
            case "WATCHING":
                return .watching
            case "FINISHED":
                return .finished
            default:
                return .empty
            }
        }
}

enum AnimationInfoTab: String, CaseIterable {
    case animationInfo = "작품 정보"
    case reviewInfo = "리뷰"
    case community = "커뮤니티"

    var title: String { self.rawValue }
}
#Preview {
    AppDIContainer.makeAnimeDetailView(animeId: 0)
}
