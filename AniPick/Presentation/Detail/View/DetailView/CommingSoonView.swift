//
//  CommingSoonView.swift
//  AniPick
//
//  Created by cho on 7/22/25.
//

import SwiftUI

struct CommingSoonView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject var viewModel: CommingSoonViewModel
    let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 0) {
                
                Spacer().frame(height: 20)
                
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
                    
                    Text("공개 예정")
                        .customFontStyle(size: 18, color: .anipickBlack)
                    
                    Spacer()
                }
                Spacer().frame(height: 30)
                
                Rectangle()
                    .foregroundColor(.clear)
                    .frame(maxWidth: .infinity)
                    .frame(height: 9)
                    .background(.gray7)
                
                
                // TODO: 19세 토글 및 최신순 토글
                // viewModel의 값 가져와서 판단
                
                HStack(spacing: 0) {
                    Text("19세")
                        .customFontStyle(size: 16, color: .point)
                    
                    Button {
                        self.viewModel.toggleIncludeAdult()
                    } label: {
                        Image(self.viewModel.isIncludeAdult ? .pinkToggle : .toggleDisable)
                    }
                    
                    Spacer()
                    Button {
                        DLog("sort category 선택창 나오도록 수정")
                        self.viewModel.isShowSortCategoryOptionView.toggle()
                    } label: {
                        HStack(alignment: .center, spacing: 0) {
                            Text(self.viewModel.selectedCategory.title)
                                .customFontStyle(size: 14, color: .gray8)
                                .padding(.trailing, 4)
                            Image(systemName: self.viewModel.isShowSortCategoryOptionView ? "chevron.up" : "chevron.down")
                                .resizable()
                                .foregroundColor(.gray8)
                                .frame(width: 9, height: 6)
                        }
                    }
                }
                .padding(20)
                
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 24) {
                        ForEach(viewModel.commingSoonAnimeList, id: \.self) { item in
                            self.animationCell(item: item) {
                                self.viewModel.tappedAnime(animeId: item.animeId ?? 0)
                            }
                            .onAppear {
                                if item == viewModel.commingSoonAnimeList.last {
                                    Task { await viewModel.loadMoreCommingSoonInfo() }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            
            if viewModel.isShowSortCategoryOptionView {
                getSortOptionView(sort: viewModel.selectedCategory)
                    .padding(.trailing, 20)
                    .offset(y: 130)
                    .zIndex(2)
                    .animation(.easeInOut, value: viewModel.isShowSortCategoryOptionView)
            }
        }
            
            .navigationBarBackButtonHidden(true)
            .onAppear {
                viewModel.fetchCommingSoonInfo()
                
            }
      
    }
    
    private func animationCell(item: UpcomingAnime, action: @escaping () -> Void) -> some View {
        return Button {
            action()
        } label: {
            VStack(spacing: 0) {
                ZStack(alignment: .topLeading) {
                    if let url = item.coverImageUrl {
                        AsyncImage(url: URL(string: url)) { phase in
                            switch phase {
                            case .empty:
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.gray.opacity(0.2))
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxWidth: .infinity)
                                    .clipped()
                            case .failure:
                                Image(systemName: "photo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxWidth: .infinity)
                            @unknown default:
                                EmptyView()
                            }
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                Text(item.title ?? "--")
                    .customFontStyle(size: 14, color: .anipickBlack)
                    .lineLimit(2)
                    .padding(.top, 6)
                
                if let releaseDate = item.releaseDate {
                    Text(item.releaseDate ?? "-")
                        .customFontStyle(size: 12, color: .gray8)
                }
            }
        }
    }
    
    private func getSortOptionView(sort: CommingSoonSortCategory) -> some View {
        return VStack(spacing: 0) {
            ForEach(CommingSoonSortCategory.allCases, id: \.self) { option in
                Button {
                    self.viewModel.selectedCategory = option
                    self.viewModel.tappedSortButton()
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


enum CommingSoonSortCategory: String, CaseIterable {
    case latest
    case popularity
    case startDate
    
    var title: String {
        switch self {
        case .latest:
            return "최신순"
        case .popularity:
            return "인기순"
        case .startDate:
            return "방영 예정 순"
        }
    }
}


