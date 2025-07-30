//
//  ReviewDetailInfoView.swift
//  AniPick
//
//  Created by cho on 7/13/25.
//

import SwiftUI

struct ReviewDetailInfoView: View {
    @StateObject var viewModel: AnimationInfoViewModel
    @Binding var selectedSortOption: SortOption
    @Binding var isShowOnlyReview: Bool
    @Binding var isShowSortOptionView: Bool
    @Binding var starRating: Int
    
    @State private var likeCount: Int = 3
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 0) {
                // TODO: main body가 너무 길어짐. 따로 함수뷰로 분리 필요
                if viewModel.reviewContent.isEmpty {
                    ZStack {
                        Rectangle()
                            .frame(height: 123)
                            .frame(maxWidth: .infinity)
                            .cornerRadius(8)
                            .foregroundColor(.gray7)
                        
                        
                        VStack(alignment: .center, spacing: 0) {
                            self.starView(starRating: self.$viewModel.myReviewCount)
                                .padding(.bottom, 16)
                            
                            Text("(\(self.viewModel.myReviewCount, specifier: "%.1f")/5.0)")
                            
                                .customFontStyle(size: 20, color: .gray6, weight: .bold)
                        }
                    }
                    .padding(.bottom, 12)
                    
                    Button {
                        DLog("상세 리뷰 작성하기")
                        viewModel.registerStarRating()
                        viewModel.moveToWriteReview()
                    } label: {
                        Text("상세 리뷰 작성하기")
                            .foregroundColor(Color.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(viewModel.myReviewCount > 0 ? .anipickPrimary : Color.gray6)
                    }
                    .cornerRadius(8)
                } else {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("내 리뷰")
                            .customFontStyle(size: 18, color: .anipickBlack, weight: .black)
                            .padding(.bottom, 13)
                        
                        VStack(alignment: .leading, spacing: 0) {
                            HStack {
                                self.smallStarView(starRating: self.viewModel.myReviewCount)
                                Text(String(format: "%.1f", self.viewModel.myReviewCount))
                                    .customFontStyle(size: 14, color: .gray8)
                                
                                Spacer()
                                
                                Text("2024.01.23")
                                    .customFontStyle(size: 12, color: .gray6)
                                
                            }
                            .padding(.bottom, 16)
                            // 리뷰 내용
                            Text(viewModel.reviewContent)
                                .customFontStyle(size: 16, color: .anipickBlack, weight: .semibold)
                                .padding(.bottom, 16)
                            
                            // 좋아요 + 더보기
                            HStack {
                                HStack(spacing: 4) {
                                    Image(systemName: "heart")
                                        .resizable()
                                        .frame(width: 14, height: 14)
                                        .foregroundColor(.gray)
                                    
                                    Text("\(likeCount)")
                                        .customFontStyle(size: 14, color: .gray6)
                                }
                                
                                Spacer()
                                
                                Image(.moreVerticalGray)
                                
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
                    
                    VStack(alignment: .leading, spacing: 0) {
                        Spacer()
                        Text("\(viewModel.reviewCount)")
                            .customFontStyle(size: 14, color: .gray6)
                    }
                    
                    
                    Spacer()
                    
                    // TODO: 스포일러 토글 값 필요
                    Text("스포일러")
                        .customFontStyle(size: 16, color: .anipickSecondary, weight: .bold)
                    
                    Image(.toggleEnable)
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
                                Text(selectedSortOption.rawValue)
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
                    
                    ForEach(viewModel.reviewList, id: \.self) { item in
                        RecentReviewCell(item: item) { id, buttonFrame in
                            DLog("button tapped")
                        }
                        .onTapGesture {
                            if item.isMine! {
                                viewModel.moveToRewriteReview(starRating: item.rating ?? 0.0)
                            }
                        }
                        .padding(.bottom, 12)
                        .padding(.horizontal, 20)
                    }

                    
                    Spacer()
                    
                }
                .background(Color.gray7)
                .padding(.horizontal, -20)
                
                
                
            }
            
            if self.isShowSortOptionView {
                SortDropdownView2(
                    selectedOption: self.$selectedSortOption) { option in
                        self.selectedSortOption = option
                        self.isShowSortOptionView.toggle()
                    }
                    .padding(.top, 140)
                    .padding(.trailing, 20)
            }
        }
        
    }
    private func smallStarView(starRating: Double) -> some View {
        return HStack(spacing: 0) {
            ForEach(1...5, id: \.self) { starIdx in
                Button {
                    self.starRating = starIdx
                } label: {
                    Image(starIdx <= self.starRating ? .fillPickStar : .unfillStar)
                        .resizable()
                        .frame(width: 20, height: 20)
                }
                .padding(.trailing, 4)
                
            }
        }
    }
    
    // TODO: 0.5점도 체크 가능하게 만들기 -> 만들어둔거 있음,,,,교체하기
    private func starView(starRating: Binding<Double>) -> some View {
        return HStack(spacing: 0) {
            ForEach(1...5, id: \.self) { starIdx in
                Button {
                    starRating.wrappedValue = Double(starIdx)
                } label: {
                    Image(starIdx <= Int(starRating.wrappedValue) ? .fillPickStar : .unfillStar)
                        .resizable()
                        .frame(width: 32, height: 32)
                }
                .padding(.trailing, 4)
                
            }
        }
    }
}

//#Preview {
//    ReviewDetailInfoView(
//        viewModel: AnimationInfoViewModel(animeId: <#Int#>, navigationManager: <#NavigationManager#>),
//        selectedSortOption: .constant(.latest),
//        isShowOnlyReview: .constant(false),
//        isShowSortOptionView: .constant(false),
//        starRating: .constant(3))
//}
