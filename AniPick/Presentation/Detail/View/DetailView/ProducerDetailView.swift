//
//  ProducerDetailView.swift
//  AniPick
//
//  Created by cho on 7/5/25.
//

import SwiftUI

struct ProducerDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject var viewModel: ProducerDetailViewModel
    
    let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            NavigationBackButtonView(title: viewModel.producerName) {
                dismiss()
            }
            
            Spacer().frame(height: 30)
            
            ScrollView(showsIndicators: false) {
                self.makeProducerView(producerList: self.viewModel.producerList)
            }
        }
        .navigationBarBackButtonHidden()
        .background(Color.white)
        .onAppear {
            self.viewModel.fetchProducerInfo()
        }
    }
    
    private func makeProducerView(producerList: [(String, [AnimeWithSeasonYear])]) -> some View {
        return VStack(alignment: .leading, spacing: 0) {
            ForEach(producerList, id: \.0) { (year, itemList) in
                self.sectionDivder()
                
                Spacer().frame(height: 24)
                
                HStack(spacing: 0) {
                    self.yearTag(year: year)
                        .padding(.bottom, 20)
                        .padding(.leading, 20)
                    
                    Spacer()
                }
                
                LazyVGrid(columns: columns, spacing: 24) {
                    ForEach(itemList.indices, id: \.self) { idx in
                        let item = itemList[idx]
                        animationCell(item: item)
                            .onAppear {
                                viewModel.loadMoreIfNeeded(currentIndex: idx)
                            }
                    }

                }
                .padding(.horizontal, 20)
                
                Spacer().frame(height: 32)
                
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    private func yearTag(year: String) -> some View {
        return VStack(alignment: .leading, spacing: 0) {
            Text(year)
                .padding(.vertical, 7)
                .padding(.horizontal, 8)
                .customFontStyle(size: 14, color: .anipickBlack)
                .background(Color.gray5)
                .cornerRadius(32)
        }
    }
    
    
    private func animationCell(item: AnimeWithSeasonYear) -> some View {
        return Button {
            self.viewModel.moveToDetailAnimeView(animeId: item.animeId ?? 0)
        } label: {
            VStack(spacing: 0) {
                AnimeCommonCellWithTitle(
                    imageUrl: item.coverImageUrl,
                    width: nil,
                    height: 162,
                    title: item.title
                )
            }
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

//
//#Preview {
//    AppDIContainer.makeProducerDetailView()
//}
