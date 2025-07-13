//
//  StarRatingComponentView.swift
//  AniPick
//
//  Created by cho on 5/18/25.
//

import SwiftUI

struct StarRatingComponentView: View {
    
    @State private var starRating: Double = 0
    @State private var contentWidth: CGFloat = 100
    
    init(starRating: Double) {
        self.starRating = starRating
    }
    
    private let starCount = 5
    private let starSize: CGFloat = 20
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
                            .frame(width: 20, height: 20)
                    }
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            print(value)
                            updateRating(with: value.location.x)
                        }
                )
            }
            
            Text("(\(self.starRating, specifier: "%.1f"))")
                .padding(.leading, 8)
                .font(.system(size: 14))
                .foregroundStyle(.point)
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
    
    private func updateRating(with xPosition: CGFloat) {
        let clampedX = min(max(0, xPosition), totalWidth)
        let rawRating = Double(clampedX / (starSize + spacing))
        let roundedRating = (rawRating * 2).rounded(.toNearestOrEven) / 2.0
        starRating = roundedRating
        print("🐳 \(starRating)")
    }
}

#Preview {
    StarRatingComponentView(starRating: 3)
}
