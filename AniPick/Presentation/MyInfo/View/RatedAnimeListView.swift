//
//  RatedAnimeListView.swift
//  AniPick
//
//  Created by cho on 7/5/25.
//

import SwiftUI
import PopupView

struct RatedAnimeListView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject var viewModel: RatedAnimeListViewModel
    
    @State private var selectedSortOption: RatedSortOption = .latest
    @State private var isShowOptionView: Bool = false
    let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)
    
    @State private var sortButtonFrame: CGRect = .zero
    @State private var optionViewFrame: CGRect = .zero
    @State private var myReviewId: Int = 0
    
    @State private var animeId: Int = 0
    @State private var reviewContent: String = ""
    @State private var starRating: Double = 0
    
    @State private var isShowToastReviewDelete: Bool = false
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 0) {
                NavigationBackButtonView(title: "평가한 작품") {
                    dismiss()
                }
                .padding(.top, 12)
                
                Spacer().frame(height: 30)
                
                ScrollView(.vertical, showsIndicators: false) {
                    GeometryReader { geo in
                        Color.clear
                            .onChange(of: geo.frame(in: .global).minY) { newValue in
                                DLog("🌀 스크롤 offset 변경됨: \(newValue)")
                                self.isShowOptionView = false
                            }
                    }
                    .frame(height: 0)
                    VStack(alignment: .leading, spacing: 0) {
                        Spacer().frame(height: 32)
                        
                        HStack(alignment: .center, spacing: 0) {
                            Text("총 \(viewModel.totalCount ?? 0)개")
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
                                            self.sortButtonFrame = proxy.frame(in: .global)
                                        }
                                        .onChange(of: viewModel.isShowSortOptionView) { _ in
                                            self.sortButtonFrame = proxy.frame(in: .global)
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
                        
                        if self.viewModel.ratedReviewList.isEmpty {
                            self.makeEmptyView()
                        } else {
                            LazyVStack(spacing: 0) {
                                ForEach(viewModel.ratedReviewList, id: \.self) { item in
                                    MyReviewCell(item: item) { id, buttonFrame in
                                        DLog("button tapped")
                                        // TODO: 이거 눌렀을 때, 삭제/수정 떠야함
                                        self.isShowOptionView.toggle()
                                        self.optionViewFrame = buttonFrame
                                        self.myReviewId = id
                                        self.animeId = item.animeId ?? 0
                                        self.reviewContent = item.reviewContent ?? ""
                                        self.starRating = item.rating ?? 0
                                    } onCellTapped: { item in
                                        DLog("cell tappedtappped")
                                        self.viewModel.moveToAnimeDetail(animeId: item.animeId ?? 0)
                                    }
                                    .onAppear {
                                        if item == viewModel.ratedReviewList.last && viewModel.ratedReviewList.count > 6 {
                                            DLog("왜 안나옴여")
                                            viewModel.loadMoreAnimeList()
                                        }
                                    }
                                }
                                .padding(.bottom, 12)
                            }
                            
                            
                            Spacer()
                        }
                        
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
                .position(x: sortButtonFrame.maxX - 40, y: sortButtonFrame.maxY + 64)
            }
            
            if self.isShowOptionView {
                MyReviewPopupView(isShowBlockMenu: self.$isShowOptionView) {
                    // 삭제 액션
                    self.isShowOptionView = false
                    self.viewModel.deleteMyReview(reviewId: self.myReviewId)
                    self.isShowToastReviewDelete.toggle()
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        self.isShowToastReviewDelete = false
                    }
                } editAction: {
                    // 수정 액션
                    // TODO: 리뷰 수정 페이지로 이동
                    self.isShowOptionView = false
                    self.viewModel.moveToEditReview(starRating: self.starRating, animeId: self.animeId, reviewContent: self.reviewContent)
                }
                .position(x: self.optionViewFrame.minX, y: self.optionViewFrame.minY + 50)
            }
        }
        .background(Color.gray7)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            viewModel.fetchRatedAnimeList()
        }
        .onReceive(NotificationCenter.default.publisher(for: .reloadRatedAnime)) { _ in
            viewModel.fetchRatedAnimeList()
        }
        .onDisappear {
            self.isShowToastReviewDelete = false
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
                .closeOnTap(true)
                .closeOnTapOutside(true)
                .dismissCallback {
                    // popup이 사라질 때 상태 초기화
                    self.isShowToastReviewDelete = false
                }
        }
    }
    
    private func makeEmptyView() -> some View {
        return VStack(spacing: 0) {
            Spacer()
                .frame(height: 120)
            
            Image(.emptyToWatchListIcon)
                .resizable()
                .frame(width: 148, height: 148)
                .padding(.bottom, 28)
            
            Text("앗! 아직 평가한 작품이 없네요.")
                .customFontStyle(size: 16, color: .gray8)
            
            Spacer()
            
        }
        .frame(maxWidth: .infinity)
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
    
    var request: String {
        switch self {
        case .latest:
            return "latest"
        case .like:
            return "likes"
        case .highRating:
            return "ratingDesc"
        case .lowRating:
            return "ratingAsc"
        }
    }
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
