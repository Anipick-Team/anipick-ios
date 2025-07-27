//
//  RatedAnimeListView.swift
//  AniPick
//
//  Created by cho on 7/5/25.
//

import SwiftUI

struct RatedAnimeListView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject var viewModel: RatedAnimeListViewModel
    
    @State private var selectedSortOption: SortOption = .latest
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 0) {
                NavigationBackButtonView(title: "평가한 작품") {
                    dismiss()
                }
                .padding(.horizontal, -20)
                
                Spacer().frame(height: 30)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        Spacer().frame(height: 32)
                        
                        HStack(alignment: .center, spacing: 0) {
                            Text("총 11개")
                            Spacer()
                            
                            // TODO: 최신순, 좋아요 순, 평가 순 등 팝업 필요
                            Button {
                                DLog("정렬 순서 변경")
                                self.viewModel.isShowSortOptionView.toggle()
                            } label: {
                                HStack(alignment: .center, spacing: 0) {
                                    Text(selectedSortOption.rawValue)
                                        .padding(.trailing, 4)
                                    Image(systemName: self.viewModel.isShowSortOptionView ? "chevron.up" : "chevron.down")
                                        .resizable()
                                        .frame(width: 9, height: 6)
                                }
                            }
                            
                        }
                        .customFontStyle(size: 14, color: .gray8)
                        .foregroundColor(Color.gray8)
                        .padding(.bottom, 13)
                        
                        
                        Button {
                            viewModel.isShowOnlyReview.toggle()
                        } label: {
                            HStack(alignment: .center, spacing: 0) {
                                Text("리뷰만 보기")
                                    .padding(.trailing, 4)
                                
                                Image(viewModel.isShowOnlyReview ? .toggleEnable : .toggleDisable)
                                
                                Spacer()
                                
                            }
                        }
                        .customFontStyle(size: 14, color: viewModel.isShowOnlyReview ? Color.anipickSecondary : Color.gray8)
                        
                        Spacer().frame(height: 20)
                        
                        
                        // TODO: 데이터 받아와서 처리 -> ForEach로 변경
//                        RecentReviewCell(id: 3) { id, buttonFrame in
//                            DLog("button tapped")
//                        }
//                        .padding(.bottom, 12)
//                        
//                        RecentReviewCell(id: 3) { id, buttonFrame in
//                            DLog("button tapped")
//                        }
//                        .padding(.bottom, 12)
//                        
//                        RecentReviewCell(id: 3) { id, buttonFrame in
//                            DLog("button tapped")
//                        }
//                        .padding(.bottom, 12)
//                        
//                        RecentReviewCell(id: 3) { id, buttonFrame in
//                            DLog("button tapped")
//                        }
                        .padding(.bottom, 12)
                        
                        Spacer()
                        
                        
                    }
                    .padding(.horizontal, 20)
                    .background(Color.gray7)
                }
            }

            if viewModel.isShowSortOptionView {
                SortDropdownView(
                    selectedOption: self.$selectedSortOption) { option in
                        self.selectedSortOption = option
                        self.viewModel.isShowSortOptionView.toggle()
                    }
                    .padding(.top, 110)
                    .padding(.trailing, 20)
            }
            
            
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(.chevronLeft)
                        .foregroundColor(.black)
                }
            }
        }
    }
}

struct SortDropdownView: View {
    @Binding var selectedOption: SortOption
    var onSelect: (SortOption) -> Void

    var body: some View {
        VStack(spacing: 0) {
            ForEach(SortOption.allCases, id: \.self) { option in
                Button {
                    onSelect(option)
                } label: {
                    Text(option.rawValue)
                        .customFontStyle(size: 14, color: .anipickBlack)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .background(Color.white)
                        .padding(.vertical, 13)
                }
                Rectangle()
                    .frame(maxWidth: .infinity)
                    .frame(height: 1)
                    .foregroundColor(.gray7)
                    .padding(.horizontal, 15)
            }
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 4)
        .frame(width: 91)
    }
}


enum SortOption: String, CaseIterable {
    case latest = "최신순"
    case like = "좋아요 순"
    case highRating = "평가 높은 순"
    case lowRating = "평가 낮은 순"
}

#Preview {
    AppDIContainer.makeMyInfoRatedAnimeView()
}
