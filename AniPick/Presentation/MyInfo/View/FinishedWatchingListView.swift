//
//  FinishedWatchingListView.swift
//  AniPick
//
//  Created by cho on 7/5/25.
//

import SwiftUI

struct FinishedWatchingListView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject var viewModel: MyInfoViewModel
    let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)
        
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            NavigationBackButtonView(title: "다 본 애니") {
                dismiss()
            }
            .padding(.horizontal, -20)
            
            Spacer().frame(height: 30)
            
            self.sectionDivder()
                .padding(.horizontal, -20)
            
            Spacer().frame(height: 20)
            
            Text("총 \(viewModel.finishedListCount)개")
                .customFontStyle(size: 14, color: .gray8)
                .padding(.bottom, 20)
            
            ScrollView {
                LazyVGrid(columns: columns, spacing: 24) {
                    ForEach(viewModel.finishedList, id: \.self) { item in
                        self.animationCell(item: item) {
                            self.viewModel.moveToDetailAnime(animeId: item.animeId ?? 0)
                        }
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
        .navigationBarBackButtonHidden(true)
        .padding(.horizontal, 20)
        .background(Color.white)
        .onAppear {
            self.viewModel.fetchFinishedList()
        }
    }
    
    
    
    private func animationCell(item: ToWatchAnime, action: @escaping () -> Void) -> some View {
        return Button {
            action()
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                AnimeCommonCellWithTitle(
                    imageUrl: item.coverImageUrl,
                    width: nil,
                    height: 162,
                    title: item.title
                )
                
                HStack(spacing: 0) {
                    Text("내 평가")
                        .customFontStyle(size: 12, color: .gray8)
                        .padding(.trailing, 4)
                    
                    Image(.fillPickStar)
                        .resizable()
                        .frame(width: 12, height: 12)
                        .padding(.trailing, 2)
                    
                    Text("\(item.myRating ?? 0, specifier: "%.1f")")
                        .customFontStyle(size: 14, color: .point)
                    
                    Spacer()
                    
                }
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

#Preview {
    AppDIContainer.makeMyInfoFinishedWatchingView()
}
