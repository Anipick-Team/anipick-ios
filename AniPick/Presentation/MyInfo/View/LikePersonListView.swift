//
//  LikePersonListView.swift
//  AniPick
//
//  Created by cho on 7/5/25.
//


import SwiftUI

struct LikePersonListView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject var viewModel: LikePersonViewModel
    let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            NavigationBackButtonView(title: "좋아요한 인물") {
                dismiss()
            }
            .padding(.horizontal, -20)
            
            Spacer().frame(height: 30)
            
            self.sectionDivder()
                .padding(.horizontal, -20)
            
            Spacer().frame(height: 20)
            
            Text("총 \(viewModel.likedPersonCount)명")
                .customFontStyle(size: 14, color: .gray8)
                .padding(.bottom, 20)
            
            ScrollView {
                LazyVGrid(columns: columns, spacing: 24) {
                    ForEach(viewModel.likedPersonList, id: \.self) { item in
                        // TODO: API 에서 데이터 가져와서 보여줘야함
                        personCell(item: item)
                            .onAppear {
                                self.viewModel.fetchNextPage(personId: item.personId ?? 0)
                            }
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
        .navigationBarBackButtonHidden(true)
        .padding(.horizontal, 20)
        .background(Color.white)
    }
    
    
    
    private func personCell(item: LikedRatedPerson) -> some View {
        return Button {
            self.viewModel.moveToPersonDetailView(personId: item.personId ?? 0)
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                ZStack(alignment: .topLeading) {
                    if let url = item.profileImageUrl {
                        AsyncImage(url: URL(string: url)) { phase in
                            switch phase {
                            case .empty:
                                Image(.animeThumbnail)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 105)
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 105)
                            case .failure:
                                Image(.animeThumbnail)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 105)
                            @unknown default:
                                EmptyView()
                            }
                        }
                    }
                    
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                Text(item.name ?? "-")
                    .font(.system(size: 14))
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
    AppDIContainer.makeMyInfoLikePersonView()
}
