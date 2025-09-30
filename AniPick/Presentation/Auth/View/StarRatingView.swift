//
//  StarRatingView.swift
//  AniPick
//
//  Created by cho on 5/4/25.
//

import SwiftUI

struct StarRatingView: View {
    @State private var starRating: Double = 0.0
    let action: (Double) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                StarRatingComponentView(
                    starRating: self.starRating,
                    fontSize: 16,
                    fontColor: .point,
                    starSize: 27
                ) { star in
                    DLog("starstar - \(star)")
                    starRating = star
                }
                
                Spacer()
                
                Button {
                   action(starRating)
                } label: {
                    Text("평가하기")
                        .foregroundStyle(.white)
                        .font(.system(size: 12))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                }
                .frame(width: 74)
                .background(self.starRating > 0 ? .anipickPrimary : .gray6)
                .cornerRadius(12)
               
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(.gray7)
            .cornerRadius(4)
        }
        .background(Color.white)
        .frame(height: 68)
    }
}

#Preview {
    StarRatingView() { value in
        DLog("preview 평가하기 tapped tapped - rating: \(value)")
    }
}
