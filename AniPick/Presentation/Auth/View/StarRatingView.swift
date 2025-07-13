//
//  StarRatingView.swift
//  AniPick
//
//  Created by cho on 5/4/25.
//

import SwiftUI

struct StarRatingView: View {
    @State private var starRating: Int = 0
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                starView()
                    .padding(.trailing, 6)
                Text("(\(starRating).0/5.0)")
                    .font(.system(size: 16))
                    .foregroundStyle(starRating > 0 ? .point : .gray6)
                Spacer()
                
                Button {
                     
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
        .frame(height: 68)
    }
    
    private func starView() -> some View {
        return HStack(spacing: 0) {
            ForEach(1...5, id: \.self) { starIdx in
                Button {
                    self.starRating = starIdx
                } label: {
                    Image(starIdx <= starRating ? .fillPickStar : .unfillStar)
                        .resizable()
                        .frame(width: 27, height: 27)
                }
                .padding(.trailing, 4)
                
            }
        }
    }
}

#Preview {
    StarRatingView()
}
