//
//  StarRatingComponentView.swift
//  AniPick
//
//  Created by cho on 5/18/25.
//

import SwiftUI

struct StarRatingComponentView: View {
    
    @State private var starRating: Double = 0
    @State private var contentWidth: CGFloat
    @State private var fontSize: CGFloat
    @State private var fontColor: Color
    @State private var starSize: CGFloat
    
    
    let action: (Double) -> Void
    
    init(starRating: Double, fontSize: CGFloat, fontColor: Color, starSize: CGFloat, action: @escaping (Double) -> Void) {
        _starRating = State(initialValue: starRating)  // ✅ 언더바 붙여야 함
        self.action = action
        self.fontSize = fontSize
        self.starSize = starSize
        self.contentWidth = starSize * 5
        self.fontColor = fontColor
    }

    private let starCount = 5
    private let spacing: CGFloat = 0
    private var totalWidth: CGFloat {
        CGFloat(starCount) * starSize + CGFloat(starCount - 1) * spacing
    }
    
    
    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 0) {
                    ForEach(1...5, id: \.self) { starIdx in
                        imageName(starIdx: starIdx)
                            .resizable()
                            .frame(width: self.starSize, height: starSize)
                    }
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            DLog("star 평가 with drag - \(value)")
                            let starRating = updateRating(with: value.location.x)
                            action(starRating)
                        }
                )
            }
            
            Text("(\(self.starRating, specifier: "%.1f"))")
                .customFontStyle(size: self.fontSize, color: self.fontColor)
                .padding(.leading, 8)
                .lineLimit(1)
                .fixedSize()          

        }
        .background(
            GeometryReader { geo in
                Color.clear
                    .onAppear {
                        self.contentWidth = geo.size.width + 20
                    }
                    .onChange(of: self.starRating) { _ in
                        self.contentWidth = geo.size.width + 20
                    }
                
            }
        )
        
    }
    
    private func imageName(starIdx: Int) -> Image {
        if starRating >= Double(starIdx) {
            return Image(.fillPickStar)
        } else if starRating >= Double(starIdx) - 0.5 {
            return Image(.halfStar)
        } else {
            return Image(.unfillStar)
        }
    }
    
    private func updateRating(with xPosition: CGFloat) -> Double {
        let clampedX = min(max(0, xPosition), totalWidth)
        let rawRating = Double(clampedX / (starSize + spacing))
        let roundedRating = (rawRating * 2).rounded(.toNearestOrEven) / 2.0
        starRating = roundedRating
        DLog("🐳 \(starRating)")
        return starRating
        
    }
}

