//
//  AnimeImageCommonCell.swift
//  AniPick
//
//  Created by cho on 9/20/25.
//

import SwiftUI

struct AnimeImageCommonCell: View {
    let imageUrl: String?
    let width: CGFloat?
    let height: CGFloat?
    
    var body: some View {
        
        VStack(spacing: 0) {
            ZStack(alignment: .topLeading) {
                if let url = imageUrl {
                    AsyncImage(url: URL(string: url)) { phase in
                        switch phase {
                        case .empty:
                            placeholder
                        case .success(let image):
                            imageView(image)
                        case .failure:
                            placeholder
                            
                        @unknown default:
                            EmptyView()
                        }
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private var placeholder: some View {
        Image(.animeThumbnail)
            .resizable()
            .scaledToFit()
            .modifier(OptionalWidth(width: width))
            .frame(height: height)
            .clipped()
    }

    private func imageView(_ image: Image) -> some View {
        image
            .resizable()
            .scaledToFit()
            .modifier(OptionalWidth(width: width))
            .frame(height: height)
            .clipped()
    }
}



struct OptionalWidth: ViewModifier {
    let width: CGFloat?
    func body(content: Content) -> some View {
        if let w = width {
            content.frame(width: w)                // 고정 너비
        } else {
            content.frame(maxWidth: .infinity)     // 가득
        }
    }
}

//
//#Preview {
//    AnimeImageCommonCell(imageUrl: "https://s4.anilist.co/file/anilistcdn/media/anime/cover/medium/bx30-AI1zr74Dh4ye.jpg", animeTitle: "titlesdfadsfajsdfjlaksjdflkajsdlfk")
//}
