//
//  GenreTagComponents.swift
//  AniPick
//
//  Created by cho on 5/25/25.
//

import SwiftUI

struct GenreTagComponents: View {
    
    let title: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .customFontStyle(size: 12, color: .anipickPrimary)
                .background(Color.anipickPrimary.opacity(0.1))
                .cornerRadius(8)
        }
        .padding(.leading, 4)
    }
}
