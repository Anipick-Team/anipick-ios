//
//  FontUtils.swift
//  AniPick
//
//  Created by cho on 5/25/25.
//

import SwiftUI

struct AppTextModifier: ViewModifier {
    let fontName: String
    let size: CGFloat
    let color: Color
    let weight: Font.Weight?

    func body(content: Content) -> some View {
        content
            .font(.system(size: size, weight: weight))
            .foregroundColor(color)
    }
}

extension View {
    func customFontStyle(
        fontName: String = "Pretendard-Regular",
        size: CGFloat,
        color: Color,
        weight: Font.Weight? = nil
    ) -> some View {
        self.modifier(AppTextModifier(fontName: fontName, size: size, color: color, weight: weight))
    }
}
