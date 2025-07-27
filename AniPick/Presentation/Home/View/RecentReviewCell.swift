//
//  Untitled.swift
//  AniPick
//
//  Created by cho on 5/18/25.
//

import SwiftUI

struct RecentReviewCell: View {
    
    @State private var starRating: Double = 0
    @State private var isShowBlockMenu: Bool = false
    
    let item: ReviewItem
    let id: Int = 0
    let onReportButtonTapped: (_ id: Int, _ buttonFrame: CGRect) -> Void
    
    private let starCount = 5
    private let starSize: CGFloat = 20
    private let spacing: CGFloat = 0
    private var totalWidth: CGFloat {
        CGFloat(starCount) * starSize + CGFloat(starCount - 1) * spacing
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 0 ) {
                if let url = item.profileImageUrl {
                    AsyncImage(url: URL(string: url)) { phase in
                        switch phase {
                        case .empty:
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.2))
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80, height: 64)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        case .failure:
                            Image(systemName: "photo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80, height: 64)
                        @unknown default:
                            EmptyView()
                        }
                    }
                }
                
                // TODO: animation name
                Text(item.animeTitle ?? "--")
                    .customFontStyle(size: 16, color: .anipickBlack)
                    .padding(.leading, 8)
                
                Spacer()
            }
            
            Rectangle()
                .frame(height: 1)
                .frame(maxWidth: .infinity)
                .foregroundStyle(.gray7)
                .padding(.vertical, 19)
            
            HStack(alignment: .center, spacing: 0) {
              //  StarRatingComponentView(starRating: item.rating ?? 0.0)
                self.starRatingView(starRating: item.rating ?? 0.0)
                
                Spacer()
                
                Circle()
                    .frame(width: 30, height: 30)
                    .foregroundStyle(.gray)
                    .padding(.trailing, 8)
                
                // TODO: 닉네임 넣어야함!
                Text(item.nickname ?? "--")
                    .foregroundStyle(.anipickBlack)
                    .font(.system(size: 12))
                
            }
            
            // TODO: 리뷰 쓴 날짜 넣어야함
            Text(item.createdAt ?? "--")
                .foregroundStyle(.gray6)
                .font(.system(size: 12))
            
            
            
            Spacer().frame(height: 16)
            
            Text(item.reviewContent ?? "--")
                .lineLimit(2)
                .font(.system(size: 16))
                .foregroundStyle(.anipickBlack)
                .padding(.bottom, 4)
            
            Button {
                DLog("더보기 버튼 탭탭")
            } label: {
                HStack(alignment: .center, spacing: 0) {
                    Text("더보기")
                        .font(.system(size: 14))
                        .foregroundStyle(.anipickPrimary)
                        .padding(.trailing, 4)
                    
                    Image(.chevronDownPrimary)
                }
            }
            
            Spacer().frame(height: 20)
            
            HStack(alignment: .center, spacing: 0) {
                Button {
                    DLog("좋아요 버튼 탭탭, 누를때 fill, unfill heart로 변경되어야함")
                } label: {
                    Image(.unfilledHeart)
                        .padding(.trailing, 4)
                }
                
                // TODO: 좋아요 갯수 넣어야함
                Text("\(item.likeCount ?? 0)")
                    .foregroundStyle(.gray6)
                    .font(.system(size: 14))
                
                Spacer()
                
                
                GeometryReader { proxy in
                    Button {
                        let frame = proxy.frame(in: .global)
                        onReportButtonTapped(id, frame)
                        DLog("되었음요 탭탭")
                    } label: {
                        Image(.moreVerticalGray)
                    }
                    .frame(width: 20, height: 20)
                }
                .frame(width: 20, height: 20)
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .background(.white)
        .cornerRadius(8)
    }
    
    
    private func starRatingView(starRating: Double) -> some View {
        return HStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(1...5, id: \.self) { starIdx in
                    imageName(starRaing: starRating, starIdx: starIdx)
                        .resizable()
                        .frame(width: 20, height: 20)
                }
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if item.isMine ?? false {
                            updateRating(with: value.location.x)
                        }
                    }
            )
            Text("\(starRating, specifier: "%.1f")")
                .padding(.leading, 8)
                .customFontStyle(size: 14, color: .gray8)
        }
    }
    
    private func imageName(starRaing: Double, starIdx: Int) -> Image {
        if starRaing >= Double(starIdx) {
            return Image(.fillPickStar)
        } else if starRaing >= Double(starIdx) - 0.5 {
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
