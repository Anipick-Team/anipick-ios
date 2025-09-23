//
//  LikeAnimeListView.swift
//  AniPick
//
//  Created by cho on 7/5/25.
//

import SwiftUI

struct LikeAnimeListView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject var viewModel: LikeAnimeListViewModel
    let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            NavigationBackButtonView(title: "좋아요한 작품") {
                dismiss()
            }
            .padding(.horizontal, -20)
            
            Spacer().frame(height: 30)
            
            self.sectionDivder()
                .padding(.horizontal, -20)
            
            Spacer().frame(height: 20)
            
            // TODO: 총 갯수 가져와서 보여줘야함
            Text("총 \(viewModel.count)개")
                .customFontStyle(size: 14, color: .gray8)
                .padding(.bottom, 20)
            
            ScrollView {
                LazyVGrid(columns: columns, spacing: 24) {
                    ForEach(viewModel.animeList, id: \.self) { item in
                        // TODO: API 에서 데이터 가져와서 보여줘야함
                        animationCell(item: item)
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
        .navigationBarBackButtonHidden(true)
        .padding(.horizontal, 20)
        .background(Color.white)
    }
    
    
    
    private func animationCell(item: LikedAnime) -> some View {
        return Button {
            self.viewModel.moveToPersonDetail(animeId: item.animeId ?? 0)
        } label: {
            AnimeCommonCellWithTitle(imageUrl: item.coverImageUrl, width: nil, height: 162, title: item.title)
        }
    }
    
    @ViewBuilder
    private func sectionDivder() -> some View {
        Rectangle()
            .foregroundColor(.gray7)
            .frame(height: 12)
            .frame(maxWidth: .infinity)
            .background(.gray5)
        
    }
}

#Preview {
    AppDIContainer.makeMyInfoLikeAnimeView()
}
