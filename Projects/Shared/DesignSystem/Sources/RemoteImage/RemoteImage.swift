import SwiftUI

extension EnvironmentValues {
    /// Example 앱·Preview는 `StaticImageLoader`를 넣는다.
    @Entry public var imageLoader: any ImageLoading = RemoteImageLoader.shared
}

/// 표시 크기에 맞게 줄인 원격 이미지. 자신이 받은 크기를 채우므로 `frame`을 정해 쓴다.
///
/// ```swift
/// RemoteImage(url: anime.coverImageURL) { image in
///     image.resizable().scaledToFill()
/// } placeholder: {
///     Color.gray2
/// }
/// .frame(width: 100, height: 140)
/// .clipped()
/// ```
public struct RemoteImage<Content: View, Placeholder: View>: View {
    private struct LoadKey: Equatable {
        let url: URL?
        let maxPixelSize: Int
    }

    private let url: URL?
    private let content: (Image) -> Content
    private let placeholder: () -> Placeholder

    @Environment(\.imageLoader) private var loader
    @Environment(\.displayScale) private var displayScale
    @State private var size: CGSize = .zero
    @State private var loaded: (url: URL, image: UIImage)?

    public init(
        url: URL?,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.content = content
        self.placeholder = placeholder
    }

    public var body: some View {
        Color.clear
            .overlay {
                if let loaded, loaded.url == url {
                    content(Image(uiImage: loaded.image))
                } else {
                    placeholder()
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

    private var maxPixelSize: Int {
        return Int((max(size.width, size.height) * displayScale).rounded(.up))
    }

    private func load() async {
        guard let url, maxPixelSize > 0 else {
            return
        }
        do {
            let image = try await loader.image(for: url, maxPixelSize: maxPixelSize)
            loaded = (url, image)
        } catch {
            // 실패하면 placeholder를 계속 보여 준다
        }
    }
}

#Preview("불러옴 · 실패") {
    let url = URL(string: "https://example.com/cover.png")
    VStack(spacing: 16) {
        RemoteImage(url: url) { image in
            image.resizable().scaledToFill()
        } placeholder: {
            Color.gray.opacity(0.2)
        }
        .frame(width: 120, height: 160)
        .clipped()
        .environment(\.imageLoader, StaticImageLoader(image: UIImage(systemName: "photo")))

        RemoteImage(url: url) { image in
            image.resizable().scaledToFill()
        } placeholder: {
            Color.gray.opacity(0.2)
        }
        .frame(width: 120, height: 160)
        .environment(\.imageLoader, StaticImageLoader(image: nil))
    }
}
