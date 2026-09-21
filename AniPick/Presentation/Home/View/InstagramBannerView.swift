//
//  InstagramBannerView.swift
//  AniPick
//

import SwiftUI

struct InstagramBannerView: View {
    private let instagramURL = "https://www.instagram.com/anipick.official?igsh=Y2tkc2k1M3FmNDll"

    var body: some View {
        ZStack {
            Color(red: 0.88, green: 0.94, blue: 1.0)

            // 양쪽 인스타그램 아이콘
            HStack(spacing: 0) {
                Image(.instagramIconSmall)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 64, height: 64)
                    .padding(.leading, 4)

                Spacer()

                Image(.instagramIcon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
            }

            // 가운데 텍스트 + 버튼
            VStack(spacing: 6) {
                // 괄호는 제목과 같은 줄에만
                HStack(alignment: .center, spacing: 4) {
                    Text("[")
                        .font(.system(size: 28, weight: .thin))
                        .foregroundColor(Color(red: 0.18, green: 0.6, blue: 0.9))

                    Group {
                        Text("애니픽 ")
                            .foregroundColor(.black)
                        + Text("공식 인스타그램")
                            .foregroundColor(Color(red: 0.18, green: 0.6, blue: 0.9))
                        + Text(" 오픈!")
                            .foregroundColor(.black)
                    }
                    .font(.system(size: 18, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                    Text("]")
                        .font(.system(size: 28, weight: .thin))
                        .foregroundColor(Color(red: 0.18, green: 0.6, blue: 0.9))
                }

                Text("다양한 애니메이션 소식과 최신 업데이트 소식을\n가장 빠르게 확인해보세요!")
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)

                Button {
                    if let url = URL(string: instagramURL) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Text("팔로우 하러 가기")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color(red: 0.18, green: 0.6, blue: 0.9))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .padding(.top, 2)
            }
            .padding(.horizontal, 60)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 160)
    }
}

#Preview {
    InstagramBannerView()
}
