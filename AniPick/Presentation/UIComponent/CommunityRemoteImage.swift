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
        guard let url = URL(string: urlString) else {
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
}
