import SwiftUI

/// 애니 표지. 불러오는 중·실패·주소 없음이면 기본 썸네일을 보여 준다. 레거시 `AnimeImageCommonCell`과 같은 모양이다.
///
/// - Parameter width: nil이면 가로를 채운다
public struct AnimeCoverImage: View {
    private let url: URL?
    private let width: CGFloat?
    private let height: CGFloat?
    private let cornerRadius: CGFloat
    private let contentMode: ContentMode

    public init(
        url: String?,
        width: CGFloat?,
        height: CGFloat?,
        cornerRadius: CGFloat = 12,
        contentMode: ContentMode = .fit
    ) {
        self.url = url.flatMap { URL(string: $0) }
        self.width = width
        self.height = height
        self.cornerRadius = cornerRadius
        self.contentMode = contentMode
    }

    public var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topLeading) {
                if let url {
                    RemoteImage(url: url) { image in
                        sized(image.resizable())
                    } placeholder: {
                        placeholder
                    }
                    .modifier(OptionalWidthFrame(width: width))
                    .frame(height: height)
                    .clipped()
                } else {
                    placeholder
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        }
    }

    private var placeholder: some View {
        return sized(Image(.animeThumbnail).resizable())
    }

    private func sized(_ image: Image) -> some View {
        return
            image
            .aspectRatio(contentMode: contentMode)
            .modifier(OptionalWidthFrame(width: width))
            .frame(height: height)
            .clipped()
    }
}

/// 너비가 있으면 고정, 없으면 가로를 채운다
private struct OptionalWidthFrame: ViewModifier {
    let width: CGFloat?

    func body(content: Content) -> some View {
        if let width {
            content.frame(width: width)
        } else {
            content.frame(maxWidth: .infinity)
        }
    }
}
