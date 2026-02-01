//
//  SeriesDetailView.swift
//  AniPick
//
//  Created by cho on 7/13/25.
//

import SwiftUI

struct SeriesDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: SeriesDetailViewModel
    let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            NavigationBackButtonView(title: "관련 작품") {
                dismiss()
            }
            .padding(.horizontal, -20)
            
            Spacer().frame(height: 30)
            
            self.sectionDivder()
                .padding(.horizontal, -20)
            
            Spacer().frame(height: 20)
            
            ZStack(alignment: .bottomTrailing) {
                Rectangle()
                    .fill(Color.black)
                    .frame(height: 151)
                    .background(Color.black)
                    .cornerRadius(8)
                
                
                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        Text("\(self.viewModel.animeTitle) 의\n 관련 작품이에요!")
                            .customFontStyle(size: 24, color: .gray7, weight: .bold)
                            .padding(.top, 20)
                            .padding(.leading, 20)
                        Spacer()
                    }
                    Spacer()
                }
                
                Image(.cloud)
                    .padding(.trailing, 20)
                
            }
            .frame(height: 151)
            
            Spacer().frame(height: 24)
            
            Text("총 \(self.viewModel.count)개")
                .customFontStyle(size: 16, color: .gray8)
                .padding(.bottom, 16)
            
            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: columns, spacing: 24) {
                    ForEach(self.viewModel.animeList, id: \.self) { item in
                        // TODO: API 에서 데이터 가져와서 보여줘야함
                        AnimeCommonCellWithTitle(
                            imageUrl: item.coverImageUrl,
                            width: nil,
                            height: 162,
                            title: item.title
                        )
                        .onTapGesture {
                            self.viewModel.moveToAnimeDetail(animeId: item.animeId ?? 0)
                        }
                        .onAppear {
                            if item == viewModel.animeList.last {
                                DLog("seriesDetail 데이터 확인 - \(item) -- \(String(describing: viewModel.animeList.last))")
                                viewModel.getLoadMoreSeriesDetailInfo()
                            }
                        }
                    }
                }
            }
            
            
            
        }
        .padding(.horizontal, 20)
        .background(Color.white)
        .navigationBarBackButtonHidden()
        .onAppear {
            self.viewModel.getSeriesDetailInfo()
        }
    }
    
//    private func animationCell(item: SeriesAnime) -> some View {
//        return VStack(spacing: 0) {
//            AnimeCommonCellWithTitle(
//                imageUrl: item.coverImageUrl,
//                width: nil,
//                height: 162,
//                title: item.title
//            )
//        }
//    }
    
    @ViewBuilder
    private func sectionDivder() -> some View {
        Rectangle()
            .foregroundColor(.gray7)
            .frame(height: 12)
            .frame(maxWidth: .infinity)
            .background(.gray5)
        
    }
    
}

