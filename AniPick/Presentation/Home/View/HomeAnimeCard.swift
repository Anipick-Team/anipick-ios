//
//  HomeAnimeCard.swift
//  AniPick
//

import SwiftUI

/// 홈 화면 가로 스크롤 섹션의 포스터 카드 (Figma `Anipick_Component` › Card › home)
/// - `rank`가 있으면 포스터 좌상단에 순위 뱃지를 붙인 rank 변형으로 그린다.
struct HomeAnimeCard: View {
    let imageUrl: String?
    let title: String?
    var rank: Int? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            AnimeImageCommonCell(
                imageUrl: imageUrl,
                width: 128,
                height: 182,
                cornerRadius: 8,
                contentMode: .fill
            )
            .overlay(alignment: .topLeading) {
                if let rank {
                    rankBadge(rank)
                }
            }

            Text(title ?? "--")
                .customFontStyle(size: 16, color: .anipickBlack, weight: .medium)
                .lineSpacing(3)  // 줄 높이 140%(22.4pt)에 맞춘 근사값
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .frame(width: 128, height: 45, alignment: .topLeading)
        }
    }

    private func rankBadge(_ rank: Int) -> some View {
        Text("\(rank)")
            .font(.system(size: 14, weight: .black))
            .foregroundStyle(.white)
            .frame(width: 36, height: 36)
            .background(Color.anipickPrimary)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .padding(10)
    }
}

#Preview {
    HStack(spacing: 12) {
        HomeAnimeCard(imageUrl: nil, title: "애니제목 애니제목 애니제목 애니제목", rank: 1)
        HomeAnimeCard(imageUrl: nil, title: "애니제목")
    }
}
