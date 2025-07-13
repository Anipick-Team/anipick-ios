//
//  PersonDetailView.swift
//  AniPick
//
//  Created by cho on 7/13/25.
//

import SwiftUI

struct PersonDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let columns = Array(repeating: GridItem(.flexible(), spacing: 14), count: 2)
    
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
            
            ScrollView {
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(0..<5) { _ in
                        // TODO: API 에서 데이터 가져와서 보여줘야함
                        characterAndVoiceActorCell()
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        
    }
    
    private func characterAndVoiceActorCell() -> some View {
        var characterImage: Image = Image(systemName: "person.fill") // 예시용 이미지
        var actorImage: Image = Image(systemName: "person.fill")     // 예시용 이미지
        
        return  VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 0) {
                // 캐릭터 이미지
                characterImage
                    .resizable()
                    .scaledToFill()
                    .frame(height: 87)
                    .background(Color.gray.opacity(0.3))
                    .clipped()
                
                Rectangle()
                       .fill(Color.gray7)
                       .frame(width: 8)

                // 성우 이미지
                actorImage
                    .resizable()
                    .scaledToFill()
                    .frame(height: 87)
                    .background(Color.gray.opacity(0.3))
                    .clipped()
            }
            .frame(maxWidth: .infinity)

            HStack(spacing: 0) {
                Text("캐릭터명")
                    .customFontStyle(size: 14, color: .anipickBlack)
                    .frame(maxWidth: .infinity)

                Text("성우명")
                    .customFontStyle(size: 14, color: .anipickBlack)
                    .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 8)
            .background(Color.gray7)
        }
        .frame(maxWidth: .infinity)
        .cornerRadius(16)
        .clipped()
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
    PersonDetailView()
}
