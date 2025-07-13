//
//  VoiceActorDetailView.swift
//  AniPick
//
//  Created by cho on 7/13/25.
//

import SwiftUI

struct VoiceActorDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            NavigationBackButtonView(title: "캐릭터/성우진") {
                dismiss()
            }
            .padding(.horizontal, -20)
            
            Spacer().frame(height: 30)
            
            self.sectionDivder()
                .padding(.horizontal, -20)
            
            Spacer().frame(height: 20)
            
            
            HStack(alignment: .center, spacing: 0) {
                ZStack(alignment: .topLeading) {
                    // 회색 배경 정사각형
                    RoundedRectangle(cornerRadius: 12)
                        .foregroundColor(Color.gray.opacity(0.2))
                        .frame(width: 95, height: 95)
                    
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.trailing, 20)
                
                Text("와타다 신야")
                    .customFontStyle(size: 28, color: .anipickBlack, weight: .bold)
                    .padding(.trailing, 8)
                
                Button {
                    DLog("좋아요 버튼 탭탭탭")
                } label: {
                    Image(.unfilledHeart)
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
                
                Text("총 13개")
                    .customFontStyle(size: 14, color: .gray8, weight: .semibold)
                    .padding(.bottom, 12)
                
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 24) {
                        ForEach(0..<12) { _ in
                            // TODO: API 에서 데이터 가져와서 보여줘야함
                            personCell()
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }
        }
        .padding(.horizontal, 20)
    }
        
        
        
        
    private func personCell() -> some View {
        return VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topLeading) {
                // 회색 배경 정사각형
                RoundedRectangle(cornerRadius: 12)
                    .foregroundColor(Color.gray.opacity(0.2))
                    .frame(height: 105)

            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            Text("캐릭터 이름")
                .customFontStyle(size: 14, color: .anipickBlack)
                .lineLimit(2)
                .padding(.top, 6)
            
            Text("록은 숙녀의 소양이기엠ㄴㅇㄹ")
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

#Preview {
    VoiceActorDetailView()
}

