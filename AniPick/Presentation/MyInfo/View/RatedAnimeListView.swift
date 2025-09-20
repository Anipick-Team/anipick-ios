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
    
    @State private var selectedSortOption: RatedSortOption = .latest
    let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)
    
    @State private var sortButtonFrame: CGRect = .zero
    @State private var isShowBlockMenu: Bool = false
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 0) {
                NavigationBackButtonView(title: "평가한 작품") {
                    dismiss()
                }
                .padding(.top, 12)
                
                Spacer().frame(height: 30)
                
                ScrollView(.vertical) {
                    VStack(alignment: .leading, spacing: 0) {
                        Spacer().frame(height: 32)
                        
                        HStack(alignment: .center, spacing: 0) {
                            Text("총 \(viewModel.lastLikeCount ?? 0)개")
                            Spacer()
                            
                            // TODO: 최신순, 좋아요 순, 평가 순 등 팝업 필요
                            Button {
                                DLog("정렬 순서 변경")
                                self.viewModel.isShowSortOptionView.toggle()
                            } label: {
                                HStack(alignment: .center, spacing: 0) {
                                    Text(viewModel.sortCategory.title)
                                        .padding(.trailing, 4)
                                    Image(systemName: self.viewModel.isShowSortOptionView ? "chevron.up" : "chevron.down")
                                        .resizable()
                                        .frame(width: 9, height: 6)
                                }
                            }
                            .background(
                                GeometryReader { proxy in
                                    Color.clear
                                        .onAppear {
                                            self.sortButtonFrame = proxy.frame(in: .named("SortOverlayArea"))
                                        }
                                        .onChange(of: viewModel.isShowSortOptionView) { _ in
                                            self.sortButtonFrame = proxy.frame(in: .named("SortOverlayArea"))
                                        }
                                }
                            )
                            
                        }
                        .customFontStyle(size: 14, color: .gray8)
                        .foregroundColor(Color.gray8)
                        .padding(.bottom, 13)
                        
                        
                        Button {
                            viewModel.isShowOnlyReview.toggle()
                            self.viewModel.fetchRatedAnimeList()
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

                        ForEach(viewModel.ratedReviewList, id: \.self) { item in
                            MyReviewCell(item: item) { id, buttonFrame in
                                DLog("button tapped")
                            }
                            .onAppear {
                                if item == viewModel.ratedReviewList.last {
                                    viewModel.loadMoreAnimeList()
                                }
                            }
                        }
                        .padding(.bottom, 12)
                        
                        Spacer()
                        
                        
                    }
                    .padding(.horizontal, 20)
                    .background(Color.gray7)
                    
                    GeometryReader { proxy in
                        Color.clear
                            .frame(height: 1)
                            .preference(
                                key: ScrollOffsetPreferenceKey.self,
                                value: proxy.frame(in: .named("SortOverlayArea")).minY
                            )
                    }

                }
                .coordinateSpace(name: "SortOverlayArea")
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { offset in
                    if viewModel.isShowSortOptionView {
                        viewModel.isShowSortOptionView = false
                    }
                }
            }
        }
        .overlay(alignment: .topLeading) {
            if viewModel.isShowSortOptionView {
                SortDropdownView(selectedOption: $viewModel.sortCategory) { option in
                    self.viewModel.sortCategory = option
                    self.viewModel.isShowSortOptionView = false
                    self.viewModel.fetchRatedAnimeList()
                }
                .frame(width: 120)
                .position(x: sortButtonFrame.minX , y: sortButtonFrame.maxY + 140)
            }
        }
        .background(Color.gray7)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            viewModel.fetchRatedAnimeList()
        }
    }
}

struct SortDropdownView: View {
    @Binding var selectedOption: RatedSortOption
    var onSelect: (RatedSortOption) -> Void

    var body: some View {
        VStack(spacing: 0) {
            ForEach(RatedSortOption.allCases, id: \.self) { option in
                Button {
                    onSelect(option)
                } label: {
                    Text(option.title)
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


struct SortDropdownView2: View {
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

enum RatedSortOption: String, CaseIterable {
    case latest
    case likes
    case ratingDesc
    case ratingAsc
    
    var title: String {
        switch self {
        case .latest:
            "최신순"
        case .likes:
            "좋아요 순"
        case .ratingDesc:
            "평가 높은 순"
        case .ratingAsc:
            "평가 낮은 순"
        }
    }
}

#Preview {
    AppDIContainer.makeMyInfoRatedAnimeView()
}
