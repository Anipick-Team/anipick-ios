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
    @State private var reviewContentLimit: Int? = 2
    @State private var currentUserTappedLike: Bool = false
    @State private var tmpHeartCount: Int = 0
    
    let item: ReviewItem
    let id: Int = 0
    let onReportButtonTapped: (_ id: Int, _ buttonFrame: CGRect) -> Void
    let tappedMoreButton: ((Bool) -> Void)?
    
    private let starCount = 5
    private let starSize: CGFloat = 18
    private let spacing: CGFloat = 0
    private var totalWidth: CGFloat {
        CGFloat(starCount) * starSize + CGFloat(starCount - 1) * spacing
    }
    
   
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 0) {
                self.starRatingView(starRating: item.rating ?? 0.0)
                
                Spacer()
                
                if let url = item.profileImageUrl {
                    AsyncImage(url: URL(string: url)) { phase in
                        switch phase {
                        case .empty:
                            Circle()
                                .frame(width: 30, height: 30)
                                .foregroundStyle(.gray)
                                .padding(.trailing, 8)
                        case .success(let image):
                            image
                                .frame(width: 30, height: 30)
                                .foregroundStyle(.gray)
                                .padding(.trailing, 8)
                        case .failure:
                            Circle()
                                .frame(width: 30, height: 30)
                                .foregroundStyle(.gray)
                                .padding(.trailing, 8)
                            
                        @unknown default:
                            EmptyView()
                        }
                    }
                }
                
                Text(item.nickname ?? "--")
                    .foregroundStyle(.anipickBlack)
                    .font(.system(size: 12))
                
            }
            
            Text(item.createdAt ?? "--")
                .foregroundStyle(.gray6)
                .font(.system(size: 12))
            
            Spacer().frame(height: 16)
            
            if let content = item.content {
                Text(content)
                    .lineLimit(self.reviewContentLimit)
                    .font(.system(size: 16))
                    .foregroundStyle(.anipickBlack)
                    .padding(.bottom, 4)
            } else {
                Text(item.reviewContent ?? "--")
                    .lineLimit(self.reviewContentLimit)
                    .font(.system(size: 16))
                    .foregroundStyle(.anipickBlack)
                    .padding(.bottom, 4)
            }
            
            Button {
                DLog("더보기 버튼 탭탭")
                if reviewContentLimit != nil {
                    reviewContentLimit = nil // 전체 보기
                } else {
                    reviewContentLimit = 2 // 다시 2줄 제한
                }
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
                    self.currentUserTappedLike.toggle()
                    tappedMoreButton?(self.currentUserTappedLike)
                    if self.currentUserTappedLike {
                        self.tmpHeartCount = 1
                    } else {
                        self.tmpHeartCount = 0
                    }
                } label: {
                    Image(self.currentUserTappedLike ? .fillHeartGreen : .unfilledHeart)
                        .resizable()
                        .frame(width: 16, height: 16)
                        .padding(.trailing, 4)
                }
                
                if let likeCount = item.likeCount {
                    Text("\(likeCount + self.tmpHeartCount)")
                        .foregroundStyle(.gray6)
                        .font(.system(size: 14))
                }
                
                Spacer()
                
             //   GeometryReader { proxy in
                    Button {
//                       let frame = proxy.frame(in: .global)
                        onReportButtonTapped(id, .zero)
                        DLog("되었음요 탭탭")
                    } label: {
                        Image(.moreVerticalGray)
                    }
                    .frame(width: 20, height: 20)
                    .anchorPreference(key: PopupMenuAnchorPreferenceKey.self, value: .bounds) { anchor in
                        anchor   // ← 상위 뷰에서 geo[anchor] 로 global frame 얻음
                    }
//                }
//                .frame(width: 20, height: 20)
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .background(Color.white)
        .cornerRadius(8)
        .onAppear {
            self.currentUserTappedLike = item.likedByCurrentUser ?? false
        }
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
                     //   if item.isMine ?? false {
                            updateRating(with: value.location.x)
                     //   }
                    }
            )
            Text("\(starRating, specifier: "%.1f")")
                .padding(.leading, 8)
                .customFontStyle(size: 13, color: .gray8)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .allowsTightening(true)
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
