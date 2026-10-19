//
//  SpoilerTagView.swift
//  AniPick
//

import SwiftUI
import DesignSystem

/// 커뮤니티 게시글의 스포일러 태그 (chips 배경 + primary 텍스트, 테두리 없음)
struct SpoilerTagView: View {
    var body: some View {
        Text("스포일러")
            .customFontStyle(size: 12, color: .anipickPrimary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.anipickPrimary.opacity(0.1))
            .cornerRadius(4)
    }
}
