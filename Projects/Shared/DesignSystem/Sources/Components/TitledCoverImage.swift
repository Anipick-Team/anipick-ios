import SwiftUI

/// 표지 아래 제목 2줄. 레거시 `AnimeCommonCellWithTitle`과 같은 모양이다.
///
/// - Parameter width: nil이면 가로를 채운다
public struct TitledCoverImage: View {
    private let url: String?
    private let width: CGFloat?
    private let height: CGFloat?
    private let title: String?

    public init(url: String?, width: CGFloat?, height: CGFloat?, title: String?) {
        self.url = url
        self.width = width
        self.height = height
        self.title = title
    }

    public var body: some View {
        VStack(spacing: 0) {
            AnimeCoverImage(url: url, width: width, height: height)

            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 0) {
                    Text(title ?? "--")
                        .textStyle(size: 14, color: .anipickBlack)
                        .lineLimit(2)
                        .padding(.top, 6)
                        .frame(alignment: .leading)
                        .multilineTextAlignment(.leading)

                    Spacer()
                }
            }
            .modifier(TitleWidth(width: width))

            Spacer()
        }
    }
}

private struct TitleWidth: ViewModifier {
    let width: CGFloat?

    func body(content: Content) -> some View {
        if let width {
            content.frame(width: width)
        } else {
            content.frame(maxWidth: .infinity)
        }
    }
}
