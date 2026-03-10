//
//  ReviewDetailInfoView.swift
//  AniPick
//
//  Created by cho on 7/13/25.
//

import SwiftUI
import PopupView

struct ReviewDetailInfoView: View {
    @StateObject var viewModel: AnimationInfoViewModel
    @Binding var scrollOffset: CGFloat
    @State private var menuFrame: CGRect = .zero
    @State private var menuFrame2: CGRect = .zero
    
   // @Binding var selectedSortOption: SortOption
    @Binding var isShowOnlyReview: Bool
    @Binding var isShowSortOptionView: Bool
    @State private var isShowBlockPopupView: Bool = false
    @Binding var starRating: Double
    @State private var lineLimit: Int? = 3
    
    @State private var selectedPopupItemReviewId: Int = 0
    @State private var selectedBlockUserId: Int = 0
    
    @State private var isPresentReportView: Bool = false
    @State private var isPresentReportReasonView: Bool = false
    @State private var isPresentBlockUserView: Bool = false
    @State private var isPresentMyReviewPopupView: Bool = false
    
    @State private var isShowToastReviewDelete: Bool = false
    @State private var isShowToastCompletedWriteReview: Bool = false
    
    @State private var collapsedHeight: CGFloat = 0   // 3줄 기준 높이
    @State private var fullHeight: CGFloat = 0        // 전체 높이
    
    @State private var scrollllll: CGFloat = 0
    let onReportButtonTapped: (_ id: Int, _ buttonFrame: CGRect) -> Void
    let onMoreButtonTapped: (_ reviewId: Int, _ blockUserId: Int, _ buttonFrame: CGRect) -> Void
    
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 0) {
                if viewModel.reviewContent.isEmpty {
                    //  if viewModel.hasMyReview == false {
                    ZStack {
                        Rectangle()
                            .frame(height: 123)
                            .frame(maxWidth: .infinity)
                            .cornerRadius(8)
                            .foregroundColor(.gray7)
                        
                        VStack(alignment: .center, spacing: 0) {
                            StarRatingComponentView(
                                starRating: self.viewModel.storedMyReviewRate,
                                fontSize: 20,
                                fontColor: .gray6,
                                starSize: 32
                            ) { star in
                                self.starRating = star
                                // viewModel.registerStarRating(ratedStar: star)
                                if viewModel.myReviewId == 0 {
                                    viewModel.registerStarRating(ratedStar: star) {
                                        self.isShowToastCompletedWriteReview.toggle()
                                    }
                                } else {
                                    viewModel.editMyReviewStar(
                                        reviewId: viewModel.myReviewId,
                                        ratedStar: star
                                    )
                                }
                            }
                        }
                    }
                    .padding(.bottom, 12)
                    
                    Button {
                        DLog("상세 리뷰 작성하기로 이동")
                        self.viewModel.storedMyReviewRate = self.starRating
                        viewModel.registerStarRating(ratedStar: self.starRating) {
                           // self.isShowToastCompletedWriteReview.toggle()
                        }
                        viewModel.moveToWriteReview()
                    } label: {
                        Text("상세 리뷰 작성하기")
                            .foregroundColor(Color.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(self.starRating > 0 ? .anipickPrimary : Color.gray6)
                    }
                    .cornerRadius(8)
                } else {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("내 리뷰")
                            .customFontStyle(size: 18, color: .anipickBlack, weight: .black)
                            .padding(.bottom, 13)
                        
                        VStack(alignment: .leading, spacing: 0) {
                            HStack {
                                StarRatingComponentView2(
                                    starRating: self.$viewModel.storedMyReviewRate,
                                    fontSize: 14,
                                    fontColor: .gray8,
                                    starSize: 20
                                ) { star in
                                    self.starRating = star
                                }
                                
                                Spacer()
                                
                                Text(self.viewModel.myReviewCreatedAt)
                                    .customFontStyle(size: 12, color: .gray6)
                                
                            }
                            .padding(.bottom, 16)
                            // 리뷰 내용
                            Text(viewModel.reviewContent)
                                .customFontStyle(size: 16, color: .anipickBlack, weight: .semibold)
                                .lineLimit(self.lineLimit)
                                .padding(.bottom, 16)
                                .overlay(
                                    VStack {
                                        // collapsed(3줄) 높이 측정용
                                        Text(viewModel.reviewContent)
                                            .customFontStyle(size: 14, color: .anipickBlack)
                                            .lineLimit(3)
                                            .fixedSize(horizontal: false, vertical: true)
                                            .background(
                                                GeometryReader { geo in
                                                    Color.clear
                                                        .onAppear { collapsedHeight = geo.size.height }
                                                        .onChange(of: geo.size.height) { collapsedHeight = $0 }
                                                }
                                            )
                                            .hidden() // 레이아웃 제외됨
                                        
                                        // full(전체줄) 높이 측정용
                                        Text(viewModel.reviewContent)
                                            .customFontStyle(size: 14, color: .anipickBlack)
                                            .lineLimit(nil)
                                            .fixedSize(horizontal: false, vertical: true)
                                            .background(
                                                GeometryReader { geo in
                                                    Color.clear
                                                        .onAppear { fullHeight = geo.size.height }
                                                        .onChange(of: geo.size.height) { fullHeight = $0 }
                                                }
                                            )
                                            .hidden() // 레이아웃 제외됨
                                    }
                                )
                            
                            if fullHeight > collapsedHeight + 1 {
                                HStack(alignment: .center, spacing: 0) {
                                    Button {
                                        DLog("더보기 버튼 탭탭")
                                        if self.lineLimit == 3 {
                                            self.lineLimit = nil
                                        } else {
                                            self.lineLimit = 3
                                        }
                                    } label: {
                                        HStack(alignment: .center, spacing: 0) {
                                            Text("더보기")
                                                .font(.system(size: 14))
                                                .foregroundStyle(.anipickPrimary)
                                                .padding(.trailing, 4)
                                            
                                            Image(.chevronDownPrimary)
                                                .rotationEffect(self.lineLimit == 3 ? .degrees(0) : .degrees(180))
                                        }
                                    }
                                    
                                    Spacer()
                                }
                                .padding(.bottom, 4)
                            }
                            
                            
                            HStack {
                                HStack(spacing: 4) {
                                    Image(systemName: "heart")
                                        .resizable()
                                        .frame(width: 14, height: 14)
                                        .foregroundColor(.gray)
                                    
                                    Text("\(viewModel.myLikeCount)")
                                        .customFontStyle(size: 14, color: .gray6)
                                }
                                
                                Spacer()
                                
                                GeometryReader { proxy in
                                    Button {
                                        let frame = proxy.frame(in: .global)
                                        self.menuFrame = proxy.frame(in: .global)
                                        DLog("되었음요 탭탭 - \(self.menuFrame)")
                                        // 삭제, 수정 팝업 띄워야함
                                        onReportButtonTapped(0, frame)
                                     //   self.isPresentMyReviewPopupView.toggle()
                                        DLog("menuFrame 위치 파악 - \(self.menuFrame)")
                                    } label: {
                                        Image(.moreVerticalGray)
                                    }
                                    .frame(width: 20, height: 20)
                                }
                                .frame(width: 20, height: 20)
                                
                            }
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.1))
                        )
                    }
                }
                
                Spacer().frame(height: 48)
                
                Rectangle()
                    .frame(maxWidth: .infinity)
                    .frame(height: 5)
                    .foregroundColor(.gray7)
                    .padding(.horizontal, -20)
                
                Spacer().frame(height: 28)
                
                HStack(alignment: .center, spacing: 0) {
                    Text("리뷰")
                        .customFontStyle(size: 24, color: .anipickBlack, weight: .bold)
                        .padding(.trailing, 8)
                    
                    Text("\(viewModel.reviewCount)개")
                        .customFontStyle(size: 14, color: .gray6)
                    
                    Spacer()
                    
                    // TODO: 스포일러 토글 값 필요
                    Text("스포일러")
                        .customFontStyle(size: 16, color: .anipickSecondary, weight: .bold)
                    
                    Button {
                        self.viewModel.isSpolier.toggle()
                        self.viewModel.fetchReview()
                    } label: {
                        Image(self.viewModel.isSpolier ?.toggleEnable : .toggleDisable)
                    }
                }
                
                Spacer().frame(height: 32)
                
                VStack(alignment: .leading, spacing: 0) {
                    Spacer().frame(height: 32)
                    
                    HStack(alignment: .center, spacing: 0) {
                        
                        Spacer()
                        // TODO: 최신순, 좋아요 순, 평가 순 등 팝업 필요
                        Button {
                            DLog("정렬 순서 변경")
                            self.isShowSortOptionView.toggle()
                        } label: {
                            HStack(alignment: .center, spacing: 0) {
                                Text(self.viewModel.selectedReviewSortOption.rawValue)
                                    .padding(.trailing, 4)
                                Image(systemName: self.isShowSortOptionView ? "chevron.up" : "chevron.down")
                                    .resizable()
                                    .frame(width: 9, height: 6)
                            }
                        }
                    }
                    .customFontStyle(size: 14, color: .gray8)
                    .foregroundColor(Color.gray8)
                    .padding(.bottom, 13)
                    .padding(.horizontal, 20)
                    
                    Spacer().frame(height: 20)
                    
                    if viewModel.reviewList.count > 0 {
                        ForEach(viewModel.reviewList, id: \.self) { item in
                            VStack(spacing: 0) {
                                GeometryReader { geo in
                                    Color.clear
                                        .onChange(of: geo.frame(in: .global).minY) { newValue in
                                            print("🌀🌀 스크롤 offset 변경됨:", newValue)
                                            self.scrollllll = newValue
//                                            if self.isShowBlockPopupView {
//                                                self.isShowBlockPopupView = false
//                                            }
                                        }
                                }
                                .frame(height: 0)
                                
                               // if item.isMine == false {
                                    RecentReviewCell(item: item,
                                                     viewModel: viewModel,
                                                     onReportButtonTapped: { id, buttonFrame in
                                        if item.isMine ?? false {
                                           // self.isPresentMyReviewPopupView.toggle()
                                            onReportButtonTapped(0, buttonFrame)
                                        } else {
                                        //    self.isShowBlockPopupView.toggle()
                                            self.selectedPopupItemReviewId = item.reviewId ?? 0
                                            self.menuFrame = buttonFrame
                                            onMoreButtonTapped(item.reviewId ?? 0, item.userId ?? 0, buttonFrame)
                                            DLog("menuFrame - \(self.menuFrame) - scoll \(self.scrollllll)")
                                            self.selectedBlockUserId = item.userId ?? 0
                                        }
                                    }, tappedMoreButton: { value in
                                        if value {
                                            self.viewModel.tappedLikeReviewButton(reviewId: item.reviewId ?? 0)
                                        } else {
                                            self.viewModel.tappedDislikeReviewButton(reviewId: item.reviewId ?? 0)
                                        }
                                    })
//                                    .onTapGesture {
//                                        if item.isMine! {
//                                            viewModel.moveToRewriteReview(starRating: item.rating ?? 0.0)
//                                        }
//                                    }
                                    .onAppear {
                                        if item.reviewId == self.viewModel.reviewList.last?.reviewId {
                                            self.viewModel.loadMoreReview()
                                        }
                                    }
                                    .padding(.bottom, 12)
                                    .padding(.horizontal, 20)
                           //     }
                            }
                        }
                    } else {
                        VStack(spacing: 0) {
                            Image(.emptyReviewIcon)
                                .resizable()
                                .frame(width: 150)
                                .padding(.bottom, 30)
                            
                            Text("아직 리뷰가 없어요!\n첫 번째 리뷰의 주인공이 되어볼까요?")
                                .customFontStyle(size: 14, color: .gray8)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    
                    Spacer()
                }
                .background(Color.gray7)
                .padding(.horizontal, -20)
            }
            
            if isShowBlockPopupView {
                ReportBlockMenuPopup(
                    isShowBlockMenu: self.$isShowBlockPopupView) {
                        // 신고 버튼 Tapped
                        DLog("신고버튼 tapped")
                        self.isShowBlockPopupView.toggle()
                        self.isPresentReportView.toggle()
                        NotificationCenter.default.post(
                            name: .presentReportPopup,
                            object: nil,
                            userInfo: ["reviewId": self.selectedPopupItemReviewId]
                        )
                    } blockAction: {
                        // 차단 버튼 Tapped
                        DLog("차단버튼 tapped")
                        self.isPresentBlockUserView.toggle()
                        self.isShowBlockPopupView.toggle()
                        NotificationCenter.default.post(
                            name: .presentBlockUserPopup,
                            object: nil,
                            userInfo: ["userId": self.selectedBlockUserId]
                        )
                    }
                    .position(x: UIScreen.main.bounds.width - 90, y: self.menuFrame.minY - self.scrollllll + 480)
                    .zIndex(1000)
            }
            
            if self.isPresentMyReviewPopupView {
                MyReviewPopupView(
                    isShowBlockMenu: self.$isPresentMyReviewPopupView) {
                        // 삭제 이벤트
                        DLog("삭제삭제")
                        self.viewModel.deleteMyReview(reviewId: viewModel.MyReview?.reviewId ?? 0) {
                            self.isShowToastReviewDelete.toggle()
                            self.viewModel.fetchReview()
                            self.viewModel.getMyReview()
                        }
                    } editAction: {
                        DLog("수정수정")
                        self.viewModel.moveToRewriteReview()
                    }
                    .position(x: UIScreen.main.bounds.width - 70, y: self.menuFrame2.minY)
                    .zIndex(1000)
            }
            
            if self.isShowSortOptionView {
                SortDropdownView2(
                    selectedOption: self.$viewModel.selectedReviewSortOption) { option in
                        self.viewModel.selectedReviewSortOption = option
                        self.isShowSortOptionView.toggle()
                        self.viewModel.fetchReview()
                    }
                    .padding(.top, 400)
                    .padding(.trailing, 0)
            }
        }
        .background(Color.white)
        .onAppear {
            self.starRating = self.viewModel.storedMyReviewRate
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.viewModel.getMyReview()
                self.viewModel.fetchReview()
            }
        }
        .onDisappear {
            self.isShowToastReviewDelete = false
            self.isShowToastCompletedWriteReview = false
        }
        .popup(isPresented: self.$isShowToastReviewDelete) {
            Text("리뷰 삭제가 완료되었습니다.")
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
        .popup(isPresented: self.$isShowToastCompletedWriteReview) {
            Text("리뷰가 성공적으로 작성되었습니다!")
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
    
}

struct MenuFrameKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}
