//
//  RecentReviewView.swift
//  AniPick
//
//  Created by cho on 5/18/25.
//

import SwiftUI
import PopupView

struct RecentReviewView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var menuFrame: CGRect = .zero
    @State private var isShowBlockMenu: Bool = false
    @StateObject var viewModel: RecentReviewViewModel
    
    @State private var isShowReportPopupView: Bool = false
    @State private var isShowBlockUser: Bool = false
    @State private var selectedPopupItemReviewId: Int = 0
    @State private var selectedBlockUserId: Int = 0
    @State private var currentUserTappedLike: Bool = false
    
    @State private var isShowToastBlockUser: Bool = false
    @State private var isShowToastReportUser: Bool = false
    
    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 0) {
                ZStack {
                    HStack(alignment: .center, spacing: 0) {
                        Button {
                            DLog("뒤로가기 버튼 탭탭")
                            dismiss()
                        } label: {
                            Image(.chevronLeft)
                                .resizable()
                                .frame(width: 24, height: 24)
                        }
                        .padding(.leading, 20)
                        Spacer()
                    }
                    
                    Spacer()
                    
                    Text("최근 리뷰")
                        .customFontStyle(size: 18, color: .anipickBlack)
                    
                    Spacer()
                }
                .padding(.top, 12)
                
                Spacer().frame(height: 30)
                
                ZStack(alignment: .topLeading) {
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 0) {
                            GeometryReader { geo in
                                Color.clear
                                    .onChange(of: geo.frame(in: .global).minY) { newValue in
                                        DLog("🌀 스크롤 offset 변경됨: \(newValue)")
                                        if self.isShowBlockMenu {
                                            self.isShowBlockMenu = false
                                        }
                                    }
                            }
                            .frame(height: 0)
                            ForEach(viewModel.recentReviewList, id: \.self) { item in
                                RecentReviewCellInHome(
                                    item: item,
                                    viewModel: viewModel,
                                    onReportButtonTapped: { id, buttonFrame in
                                    self.isShowBlockMenu.toggle()
                                    self.selectedPopupItemReviewId = item.reviewId ?? 0
                                    self.menuFrame = buttonFrame
                                    self.selectedBlockUserId = item.userId ?? 0
                                }, tappedMoreButton: { value in
                                    if value {
                                        self.viewModel.tappedLikeReviewButton(reviewId: item.reviewId ?? 0)
                                    } else {
                                        self.viewModel.tappedDislikeReviewButton(reviewId: item.reviewId ?? 0)
                                    }

                                })
                                .onTapGesture {
                                    self.viewModel.moveToDetailAnimation(animeId: item.animeId ?? 0)
                                }
                                .padding(.vertical, 16)
                                .padding(.horizontal, 20)
                                .onAppear {
                                    /// ⬇️ Load More 트리거
                                    if item.reviewId == viewModel.recentReviewList.last?.reviewId {
                                        viewModel.fetchLoadMoreRecentReview()   
                                    }
                                }
                            }
                        }
                        .cornerRadius(8)
                    }
                    
                    if isShowBlockMenu {
                        ReportBlockMenuPopup(isShowBlockMenu: self.$isShowBlockMenu) {
                            // report action
                            DLog("신고 액션")
                            
                            isShowBlockMenu = false
                            isShowReportPopupView = true
                        } blockAction: {
                            // block action
                            isShowBlockMenu = false
                            self.isShowBlockUser.toggle()
                            self.viewModel.fetchRecentReview()
                        }
                        .position(x: UIScreen.main.bounds.width - 70, y: self.menuFrame.minY - 40)
                        .zIndex(1000)
                    }
                }
            }
            .background(.gray7)
            .navigationBarBackButtonHidden(true)
            .onDisappear {
                self.isShowToastBlockUser = false
                self.isShowToastReportUser = false
            }
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
            .popup(isPresented: self.$isShowToastReportUser) {
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
            
            if isShowReportPopupView {
                ReportReviewWithReasonPopupView {
                    self.isShowReportPopupView = false
                    self.viewModel.fetchRecentReview()
                } okAction: { reportReason in
                    self.viewModel.reportReview(
                        reviewId: self.selectedPopupItemReviewId,
                        message: reportReason
                    ) { result in
                        if result {
                            self.isShowToastReportUser.toggle()
                        }
                    }
                    self.isShowReportPopupView = false
                    self.viewModel.fetchRecentReview()
                }
            }
            
            if isShowBlockUser {
                BlockUserPopupView {
                    self.isShowBlockUser = false
                } okAction: {
                    self.viewModel.blockUser(userId: self.selectedBlockUserId) { result in
                        if result {
                            self.isShowToastBlockUser.toggle()
                        }
                    }
                    self.isShowBlockUser = false
                    self.viewModel.fetchRecentReview()
                }

            }
        }
        
    }
    
}

#Preview {
    AppDIContainer.makeRecentReviewView()
}
