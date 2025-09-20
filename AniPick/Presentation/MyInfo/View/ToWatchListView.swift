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
            
            // TODO: 총 갯수 가져와서 보여줘야함
            Text("총 \(viewModel.toWatchListCount)개")
                .customFontStyle(size: 14, color: .gray8)
                .padding(.bottom, 20)
            
            ScrollView {
                LazyVGrid(columns: columns, spacing: 24) {
                    ForEach(viewModel.toWatchList, id: \.self) { item in
                        animationCell(item: item) {
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
            self.viewModel.fetchToWatchList()
        }
    }
    
    
    
    private func animationCell(item: ToWatchAnime, action: @escaping () -> Void) -> some View {
        return Button {
            action()
        } label: {
            VStack(spacing: 0) {
                ZStack(alignment: .topLeading) {
                    if let url = item.coverImageUrl {
                        AsyncImage(url: URL(string: url)) { phase in
                            switch phase {
                            case .empty:
                                Image(.animeThumbnail)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxWidth: .infinity)
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxWidth: .infinity)
                                    .clipped()
                            case .failure:
                                Image(.animeThumbnail)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxWidth: .infinity)
                            @unknown default:
                                EmptyView()
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                Text(item.title ?? "--")
                    .customFontStyle(size: 14, color: .anipickBlack)
                    .lineLimit(2)
                    .padding(.top, 6)
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
    AppDIContainer.makeMyInfoInToWatchView()
}
