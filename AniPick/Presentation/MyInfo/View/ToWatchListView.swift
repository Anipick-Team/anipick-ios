//
//  ToWatchListView.swift
//  AniPick
//
//  Created by cho on 7/5/25.
//

import SwiftUI

struct ToWatchListView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject var viewModel: MyInfoViewModel
    let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)
        
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            NavigationBackButtonView(title: "볼 애니") {
                dismiss()
            }
            .padding(.horizontal, -20)
            
            Spacer().frame(height: 30)
            
            self.sectionDivder()
                .padding(.horizontal, -20)
            
            Spacer().frame(height: 20)
            
            Text("총 \(viewModel.toWatchListCount)개")
                .customFontStyle(size: 14, color: .gray8)
                .padding(.bottom, 20)
            
            if viewModel.toWatchListCount == 0 {
                self.makeEmptyView()
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVGrid(columns: columns, spacing: 24) {
                        ForEach(viewModel.toWatchList, id: \.self) { item in
                            self.animationCell(item: item) {
                                self.viewModel.moveToDetailAnime(animeId: item.animeId ?? 0)
                            }
                            .onAppear {
                                if item.animeId  == self.viewModel.toWatchList.last?.animeId {
                                    self.viewModel.fetchToWatchList()
                                }
                            }
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }
        }
        .navigationBarBackButtonHidden(true)
        .padding(.horizontal, 20)
        .background(Color.white)
        .onAppear {
            self.viewModel.fetchToWatchList()
        }
    }
    
    private func makeEmptyView() -> some View {
        return VStack(spacing: 0) {
            Spacer()
            
            Image(.emptyToWatchListIcon)
                .resizable()
                .frame(width: 148, height: 148)
                .padding(.bottom, 28)
            
            Text("아직 볼 애니가 없어요!")
                .customFontStyle(size: 16, color: .gray8)
            
            Spacer()
            
        }
        .frame(maxWidth: .infinity)
    }
    
    private func animationCell(item: ToWatchAnime, action: @escaping () -> Void) -> some View {
        return Button {
            action()
        } label: {
            AnimeCommonCellWithTitle(
                imageUrl: item.coverImageUrl,
                width: nil,
                height: 162,
                title: item.title
            )
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
    AppDIContainer.makeMyInfoInToWatchView()
}
