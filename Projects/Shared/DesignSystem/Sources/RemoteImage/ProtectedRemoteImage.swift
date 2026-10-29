import SwiftUI

extension EnvironmentValues {
    /// 인증이 필요한 이미지(커뮤니티 첨부 등)를 받는 로더. App이 토큰을 붙이는 로더를 넣는다
    @Entry public var protectedImageLoader: any ImageLoading = RemoteImageLoader.shared
}

/// 인증이 필요한 원격 이미지. 받는 중에는 진행 표시, 실패하면 사진 아이콘을 회색 바탕에 보여 준다.
/// 레거시 `CommunityRemoteImage`와 같은 모양이다. 자신이 받은 크기를 채운다.
public struct ProtectedRemoteImage: View {
    private let url: URL?
    private let contentMode: ContentMode

    @Environment(\.protectedImageLoader) private var loader
    @Environment(\.displayScale) private var displayScale
    @State private var size: CGSize = .zero
    @State private var loaded: (url: URL, image: UIImage)?
    @State private var didFail = false

    public init(url: URL?, contentMode: ContentMode = .fill) {
        self.url = url
        self.contentMode = contentMode
    }

    public var body: some View {
        Group {
            if let loaded, loaded.url == url {
                Image(uiImage: loaded.image)
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
        .onGeometryChange(for: CGSize.self) { proxy in
            return proxy.size
        } action: { newSize in
            size = newSize
        }
        .task(id: LoadKey(url: url, maxPixelSize: maxPixelSize)) {
            await load()
        }
    }

    private struct LoadKey: Equatable {
        let url: URL?
        let maxPixelSize: Int
    }

    private var maxPixelSize: Int {
        return Int((max(size.width, size.height) * displayScale).rounded(.up))
    }

    private func load() async {
        guard let url else {
            didFail = true
            return
        }
        guard maxPixelSize > 0 else {
            return
        }
        do {
            loaded = (url, try await loader.image(for: url, maxPixelSize: maxPixelSize))
        } catch {
            didFail = true
        }
    }
}
