//
//  CharacterAndVoiceActorCellView.swift
//  AniPick
//
//  Created by cho on 9/7/25.
//

import SwiftUI

struct CharacterAndVoiceActorCellView: View {
    let characterImageUrl: String
    let charactreName: String
    let voiceActorImageUrl: String
    let voiceActorName: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
           HStack(spacing: 0) {
               // 캐릭터 이미지
                   AsyncImage(url: URL(string: characterImageUrl)) { phase in
                       switch phase {
                       case .empty:
                           // 로딩 중 placeholder
                           Image(.animeThumbnail)
                               .resizable()
                               .scaledToFill()
                               .frame(height: 95)
                               .background(Color.gray.opacity(0.3))
                               .clipped()

                       case .success(let image):
                           image
                               .resizable()
                               .scaledToFill()
                               .frame(height: 95)
                               .background(Color.gray.opacity(0.3))
                               .clipped()
                           
                       case .failure:
                           // 실패 시 fallback
                           Image(.animeThumbnail)
                               .resizable()
                               .scaledToFill()
                               .frame(height: 95)
                               .background(Color.gray.opacity(0.3))
                               .clipped()
                           
                       @unknown default:
                           EmptyView()
                       }
                   }
                   
               Rectangle()
                      .fill(Color.gray7)
                      .frame(width: 8)

               // 성우 이미지
               AsyncImage(url: URL(string: voiceActorImageUrl)) { phase in
                   switch phase {
                   case .empty:
                       // 로딩 중 placeholder
                       Image(.animeThumbnail)
                           .resizable()
                           .scaledToFill()
                           .frame(height: 95)
                           .background(Color.gray.opacity(0.3))
                           .clipped()
                       
                   case .success(let image):
                       image
                           .resizable()
                           .scaledToFill()
                           .frame(height: 95)
                           .background(Color.gray.opacity(0.3))
                           .clipped()
                       
                   case .failure:
                       // 실패 시 fallback
                       Image(.animeThumbnail)
                           .resizable()
                           .scaledToFill()
                           .frame(height: 95)
                           .background(Color.gray.opacity(0.3))
                           .clipped()
                       
                   @unknown default:
                       EmptyView()
                   }
               }
           }
           .clipShape(RoundedCorner(radius: 12, corners: [.topLeft, .topRight]))
           .frame(maxWidth: .infinity)

           HStack(spacing: 0) {
               Text(charactreName)
                   .customFontStyle(size: 14, color: .anipickBlack)
                   .frame(maxWidth: .infinity, alignment: .leading)
                   .padding(.leading, 4)

               Text(voiceActorName)
                   .customFontStyle(size: 14, color: .anipickBlack)
                   .frame(maxWidth: .infinity, alignment: .leading)
           }
           .padding(.bottom, 8)
           .background(Color.gray7)
           .frame(height: 40)
           .frame(maxWidth: .infinity)
           .clipShape(RoundedCorner(radius: 12, corners: [.bottomLeft, .bottomRight]))
       }
       .frame(maxWidth: .infinity)
       .cornerRadius(16)
       .clipped()
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect,
                                byRoundingCorners: corners,
                                cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
