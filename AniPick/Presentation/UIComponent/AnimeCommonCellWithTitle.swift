//
//  AnimeCommonCellWithTitle.swift
//  AniPick
//
//  Created by cho on 9/20/25.
//

import SwiftUI

struct AnimeCommonCellWithTitle: View {
    let imageUrl: String?
    let width: CGFloat?
    let height: CGFloat?
    let title: String?
    
    var body: some View {
        VStack(spacing: 0) {
            AnimeImageCommonCell(
                imageUrl: imageUrl,
                width: width,
                height: height
            )
            
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 0) {
                    Text(title ?? "--")
                        .customFontStyle(size: 14, color: .anipickBlack)
                        .lineLimit(2)
                        .padding(.top, 6)
                        .frame(alignment: .leading)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                }
            }
            .applyOptionalWidth(width)
            
            Spacer()
        }
    }
}

extension View {
    @ViewBuilder
    func applyOptionalWidth(_ width: CGFloat?) -> some View {
        if let w = width {
            self.frame(width: w)
        } else {
            self.frame(maxWidth: .infinity)
        }
    }
}
