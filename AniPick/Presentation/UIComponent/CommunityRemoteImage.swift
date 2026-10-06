//
//  CommunityRemoteImage.swift
//  AniPick
//

import SwiftUI
import UIKit

private enum CommunityImageCache {
    static let images = NSCache<NSURL, UIImage>()
}

/// 커뮤니티 첨부 이미지는 인증이 필요한 이미지 API를 통해 내려올 수 있어,
/// 기본 AsyncImage 대신 Authorization 헤더를 포함해 불러옵니다.
struct CommunityRemoteImage: View {
    let urlString: String
    var contentMode: ContentMode = .fill

    @State private var image: UIImage?
    @State private var didFail = false

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else {
                Color.gray5
                    .overlay {
                        if didFail {
                            Image(systemName: "photo")
                                .foregroundColor(.gray6)
                        } else {
                            ProgressView()
                        }
                    }
            }
        }
        .task(id: urlString) {
            await loadImage()
        }
    }

    private func loadImage() async {
        guard let url = resolvedURL(from: urlString) else {
            didFail = true
            DLog("커뮤니티 이미지 URL 생성 실패 - \(urlString)")
            return
        }

        if let cachedImage = CommunityImageCache.images.object(forKey: url as NSURL) {
            image = cachedImage
            return
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 30
        let accessToken = UserDefaultsManager.shared.getAccessToken()
        if !accessToken.isEmpty {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200..<300).contains(httpResponse.statusCode),
                  let loadedImage = UIImage(data: data)
            else {
                didFail = true
                DLog("커뮤니티 이미지 응답 실패 - status: \((response as? HTTPURLResponse)?.statusCode ?? -1), url: \(url.absoluteString)")
                return
            }

            CommunityImageCache.images.setObject(loadedImage, forKey: url as NSURL)
            image = loadedImage
            didFail = false
            DLog("커뮤니티 이미지 로드 성공 - url: \(url.absoluteString)")
        } catch {
            didFail = true
            DLog("커뮤니티 이미지 로드 실패 - url: \(url.absoluteString), error: \(error)")
        }
    }

    private func resolvedURL(from value: String) -> URL? {
        let path = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !path.isEmpty else { return nil }

        if let url = URL(string: path), url.scheme != nil {
            return url
        }

        // 일부 API는 이미지 식별자만 내려주므로, 마이페이지와 동일한 이미지 API 경로로 보정합니다.
        if let imageID = Int(path) {
            return URL(string: "\(NetworkManager.baseUrl)api/image/\(imageID)")
        }

        return URL(string: path, relativeTo: URL(string: NetworkManager.baseUrl))?.absoluteURL
    }
}

/// 인증이 필요한 사용자 프로필 이미지를 모든 커뮤니티 화면에서 일관되게 표시합니다.
struct CommunityProfileAvatar: View {
    let imageURL: String?
    var size: CGFloat = 36

    /// 리뷰 화면과 동일하게 `profileImageUrl`의 마지막 경로를 이미지 ID로 해석합니다.
    /// 커뮤니티 응답의 프로필 URL은 바로 표시 가능한 공개 URL이 아닐 수 있어,
    /// 실제 이미지 데이터는 `/api/image/{id}`에서 받아야 합니다.
    private var reviewCompatibleImageURL: String? {
        guard let imageURL = imageURL?.trimmingCharacters(in: .whitespacesAndNewlines),
              !imageURL.isEmpty
        else {
            return nil
        }

        let imageID = imageURL
            .split(separator: "/")
            .last
            .flatMap { Int($0) }

        guard let imageID else { return nil }

        return "\(NetworkManager.baseUrl)api/image/\(imageID)"
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.gray5)

            if let imageURL = reviewCompatibleImageURL {
                CommunityRemoteImage(urlString: imageURL, contentMode: .fill)
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
