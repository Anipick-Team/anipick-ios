import DesignSystem
import SwiftUI

/// 작성자 프로필 (레거시 `CommunityProfileAvatar`). 주소가 없으면 기본 이미지
struct CommunityProfileAvatar: View {
    let imageURL: URL?
    var size: CGFloat = 36

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.gray5)

            if let imageURL {
                ProtectedRemoteImage(url: imageURL, contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else {
                Image(.animeThumbnail)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size * 0.72, height: size * 0.72)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
}

/// 스포일러 표시 (레거시 `SpoilerTagView`)
struct SpoilerTag: View {
    var body: some View {
        Text("스포일러")
            .textStyle(size: 12, color: .anipickPrimary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.anipickPrimary.opacity(0.1))
            .cornerRadius(4)
    }
}

/// 장르 태그 (레거시 `GerneTagComponents`)
struct GenreTag: View {
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .textStyle(size: 12, color: .anipickPrimary)
                .background(Color.anipickPrimary.opacity(0.1))
                .cornerRadius(8)
        }
        .padding(.leading, 4)
    }
}

/// 화면 아래 안내 (레거시 `CommunityToast`)
struct CommunityToast: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(Color.black.opacity(0.82))
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.16), radius: 8, y: 3)
            .padding(.horizontal, 24)
    }
}
