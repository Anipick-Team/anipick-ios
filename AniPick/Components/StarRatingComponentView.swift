//
//  StarRatingView.swift
//  AniPick
//
//  Created by cho on 5/18/25.
//

import SwiftUI

struct StarRatingView: View {
    
    var starRating: Int = 3
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 0) {
                ForEach(1...5, id: \.self) { starIdx in
                    Button {
                        self.starRating = starIdx
                    } label: {
                        Image(starIdx <= starRating ? .fillPickStar : .unfillStar)
                            .resizable()
                            .frame(width: 20, height: 20)
                    }
                    .padding(.trailing, 4)
                    
                }
                
                Text("(\(self.starRating).0)")
                    .padding(.leading, 8)
                    .font(.system(size: 14))
                    .foregroundStyle(.point)
            }
        }
    }
}

#Preview {
    StarRatingView()
}
