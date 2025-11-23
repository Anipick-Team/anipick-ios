//
//  RecentReviewView.swift
//  AniPick
//
//  Created by cho on 5/18/25.
//

import SwiftUI

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
                                        print("🌀 스크롤 offset 변경됨:", newValue)
                                        if self.isShowBlockMenu {
                                            self.isShowBlockMenu = false
                                        }
                                    }
                            }
                            .frame(height: 0)
                            ForEach(viewModel.recentReviewList, id: \.self) { item in
                                RecentReviewCellInHome(item: item, onReportButtonTapped: { id, buttonFrame in
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
            
            if isShowReportPopupView {
                ReportReviewWithReasonPopupView {
                    self.isShowReportPopupView = false
                } okAction: { reportReason in
                    self.viewModel.reportReview(
                        reviewId: self.selectedPopupItemReviewId,
                        message: reportReason
                    )
                    self.isShowReportPopupView = false
                }

            }
            
            if isShowBlockUser {
                BlockUserPopupView {
                    self.isShowBlockUser = false
                } okAction: {
                    self.viewModel.blockUser(userId: self.selectedBlockUserId)
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
