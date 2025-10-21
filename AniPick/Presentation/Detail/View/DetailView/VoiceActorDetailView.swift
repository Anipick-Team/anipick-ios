//
//  VoiceActorDetailView.swift
//  AniPick
//
//  Created by cho on 7/13/25.
//

import SwiftUI

struct VoiceActorDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: VoiceActorViewModel
    let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            NavigationBackButtonView(title: "성우") {
                dismiss()
            }
            .padding(.horizontal, -20)
            
            Spacer().frame(height: 30)
            
            self.sectionDivder()
                .padding(.horizontal, -20)
            
            Spacer().frame(height: 20)
            
            
            HStack(alignment: .center, spacing: 0) {
                AsyncImage(url: URL(string: viewModel.actorImageUrl)) { phase in
                    switch phase {
                    case .empty:
                        // 로딩 중 placeholder
                        Image(.animeThumbnail)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 95, height: 95)
                            .background(Color.gray.opacity(0.3))
                            .clipped()
                        
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 95, height: 95)
                            .background(Color.gray.opacity(0.3))
                            .clipped()
                        
                    case .failure:
                        // 실패 시 fallback
                        Image(.animeThumbnail)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 95, height: 95)
                            .background(Color.gray.opacity(0.3))
                            .clipped()
                        
                    @unknown default:
                        EmptyView()
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.trailing, 20)
                
                Text(viewModel.actorName)
                    .customFontStyle(size: 28, color: .anipickBlack, weight: .bold)
                    .padding(.trailing, 8)
                
                Button {
                    DLog("좋아요 버튼 탭탭탭")
                    if viewModel.isLiked {
                        self.viewModel.cancelLikePerson()
                        viewModel.isLiked.toggle()
                    } else {
                        self.viewModel.likePerson()
                        viewModel.isLiked.toggle()
                    }
                } label: {
                    Image(viewModel.isLiked ? .filledHeartPink : .unfilledHeart)
                        .resizable()
                        .frame(width: 19, height: 19)
                }
                
            }
            
            
            Rectangle()
                .foregroundColor(.gray7)
                .frame(height: 5)
                .frame(maxWidth: .infinity)
                .background(.gray5)
                .padding(.vertical, 24)
            
            
            VStack(alignment: .leading, spacing: 0) {
                Text("참여 작품 목록")
                    .customFontStyle(size: 16, color: .anipickBlack, weight: .semibold)
                    .padding(.bottom, 20)
                
                Text("총 \(viewModel.workCount)개")
                    .customFontStyle(size: 14, color: .gray8, weight: .semibold)
                    .padding(.bottom, 12)
                
                ScrollView(showsIndicators: false) {
                    LazyVGrid(columns: columns, spacing: 24) {
                        ForEach(viewModel.workList, id: \.self) { item in
                            // TODO: API 에서 데이터 가져와서 보여줘야함
                            personCell(item: item)
                                .onAppear {
                                    self.viewModel.fetchNextPage(item: item.characterId)
                                }
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }
        }
        .navigationBarBackButtonHidden()
        .padding(.horizontal, 20)
        .background(Color.white)
    }
    
    private func personCell(item: PersonWork) -> some View {
        return VStack(alignment: .leading, spacing: 0) {
            
            AsyncImage(url: URL(string: item.characterImageUrl ?? "")) { phase in
                switch phase {
                case .empty:
                    // 로딩 중 placeholder
                    Image(.animeThumbnail)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 105)
                        .background(Color.gray.opacity(0.3))
                        .clipped()
                    
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(height: 105)
                        .background(Color.gray.opacity(0.3))
                        .clipped()
                    
                case .failure:
                    // 실패 시 fallback
                    Image(.animeThumbnail)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 105)
                        .background(Color.gray.opacity(0.3))
                        .clipped()
                    
                    
                @unknown default:
                    EmptyView()
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            Text(item.characterName)
                .customFontStyle(size: 14, color: .anipickBlack)
                .lineLimit(2)
                .padding(.top, 6)
            
            Text(item.animeTitle)
                .customFontStyle(size: 12, color: .gray8)
                .lineLimit(1)
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

