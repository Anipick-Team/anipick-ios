import SwiftUI

/// 태그를 줄 바꿈하며 배치한다 (가운데 기준). 레거시 `FlowLayout`과 같은 배치다.
public struct FlowTagLayout: Layout {
    public var spacing: CGFloat
    public var lineSpacing: CGFloat

    public init(spacing: CGFloat = 8, lineSpacing: CGFloat = 8) {
        self.spacing = spacing
        self.lineSpacing = lineSpacing
    }

    public struct Cache {
        var sizes: [CGSize] = []
    }

    public func makeCache(subviews: Subviews) -> Cache {
        return Cache(sizes: subviews.map { $0.sizeThatFits(.unspecified) })
    }

    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Cache)
        -> CGSize
    {
        guard !subviews.isEmpty else {
            return .zero
        }
        // 너비 제안이 없을 때 0으로 계산하면 태그가 한 줄에 하나씩 놓인다 — 화면 너비를 쓴다 (레거시와 같음)
        let availableWidth = proposal.width ?? UIScreen.main.bounds.width
        var totalWidth: CGFloat = 0
        var totalHeight: CGFloat = 0
        var lineWidth: CGFloat = 0
        var lineHeight: CGFloat = 0

        for size in cache.sizes {
            let itemSpacing = lineWidth == 0 ? 0 : spacing
            if lineWidth > 0 && lineWidth + itemSpacing + size.width > availableWidth {
                totalWidth = max(totalWidth, lineWidth)
                totalHeight += lineHeight + lineSpacing
                lineWidth = size.width
                lineHeight = size.height
            } else {
                lineWidth += itemSpacing + size.width
                lineHeight = max(lineHeight, size.height)
            }
        }
        totalWidth = max(totalWidth, lineWidth)
        totalHeight += lineHeight
        return CGSize(width: totalWidth, height: totalHeight)
    }

    public func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Cache
    ) {
        var lineX = bounds.minX
        var lineY = bounds.minY
        var lineHeight: CGFloat = 0

        for index in subviews.indices {
            let size = cache.sizes[index]
            let itemSpacing = lineX == bounds.minX ? 0 : spacing
            if lineX > bounds.minX && lineX + itemSpacing + size.width > bounds.maxX {
                lineY += lineHeight + lineSpacing
                lineHeight = 0
                lineX = bounds.minX
            }
            if lineX > bounds.minX {
                lineX += spacing
            }
            lineHeight = max(lineHeight, size.height)
            subviews[index].place(
                at: CGPoint(x: lineX + size.width / 2, y: lineY + size.height / 2),
                anchor: .center,
                proposal: ProposedViewSize(size)
            )
            lineX += size.width
        }
    }
}

/// 칩을 줄 바꿈하며 배치한다. 레거시 `FlowCellLayout`과 같은 배치다.
///
/// - Parameter alignTrailing: 줄을 오른쪽에 붙인다. 레거시처럼 줄 너비에 마지막 간격까지 넣어 계산한다
public struct FlowChipLayout: Layout {
    public var spacing: CGFloat
    public var alignTrailing: Bool

    public init(spacing: CGFloat = 4, alignTrailing: Bool = false) {
        self.spacing = spacing
        self.alignTrailing = alignTrailing
    }

    private struct Row {
        var subviews: [LayoutSubviews.Element] = []
        var height: CGFloat = 0
        var width: CGFloat = 0
    }

    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ())
        -> CGSize
    {
        let rows = rows(subviews, maxWidth: proposal.width ?? .infinity)
        let height = rows.reduce(0) { $0 + $1.height } + CGFloat(rows.count - 1) * spacing
        return CGSize(width: proposal.width ?? .infinity, height: height)
    }

    public func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        var y = bounds.minY
        for row in rows(subviews, maxWidth: bounds.width) {
            var x = alignTrailing ? bounds.maxX - row.width : bounds.minX
            for subview in row.subviews {
                let size = subview.sizeThatFits(.unspecified)
                subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += row.height + spacing
        }
    }

    private func rows(_ subviews: Subviews, maxWidth: CGFloat) -> [Row] {
        var rows: [Row] = []
        var current = Row()
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if current.width + size.width > maxWidth, !current.subviews.isEmpty {
                rows.append(current)
                current = Row()
            }
            current.subviews.append(subview)
            current.width += size.width + spacing
            current.height = max(current.height, size.height)
        }
        if !current.subviews.isEmpty {
            rows.append(current)
        }
        return rows
    }
}
