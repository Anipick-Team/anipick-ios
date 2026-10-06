//
//  FlowLayout.swift
//  AniPick
//
//  Created by cho on 5/4/25.
//

import SwiftUI

struct FlowLayout: Layout {
    
    var spacing: CGFloat = 8
    var lineSpacing: CGFloat = 8
    
    struct Cache {
        var sizes: [CGSize] = []
        var spacing: [CGFloat] = []
    }
    
    func makeCache(subviews: Subviews) -> Cache {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        let spacing: [CGFloat] = subviews.indices.map { index in
            guard index != subviews.count - 1 else {
                return 0
            }
            
            return subviews[index].spacing.distance(
                to: subviews[index+1].spacing,
                along: .horizontal
            )
        }
        
        return Cache(sizes: sizes, spacing: spacing)
    }
    
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Cache) -> CGSize {
        guard subviews.isEmpty == false else { return .zero }

        // 부모가 너비를 아직 제안하지 않는 순간에도 0으로 계산하지 않도록
        // 화면 너비를 fallback으로 사용한다. 0이 되면 모든 태그가 매번
        // 새 줄로 배치되어 세로 목록처럼 보이게 된다.
        let availableWidth = proposal.width ?? UIScreen.main.bounds.width
        var totalWidth: CGFloat = 0
        var totalHeight: CGFloat = 0
        var lineWidth: CGFloat = 0
        var lineHeight: CGFloat = 0

        for index in subviews.indices {
            let itemSize = cache.sizes[index]
            let itemSpacing = lineWidth == 0 ? 0 : spacing

            if lineWidth > 0 && lineWidth + itemSpacing + itemSize.width > availableWidth {
                totalWidth = max(totalWidth, lineWidth)
                totalHeight += lineHeight + lineSpacing
                lineWidth = itemSize.width
                lineHeight = itemSize.height
            } else {
                lineWidth += itemSpacing + itemSize.width
                lineHeight = max(lineHeight, itemSize.height)
            }
        }

        totalWidth = max(totalWidth, lineWidth)
        totalHeight += lineHeight

        return CGSize(width: totalWidth, height: totalHeight)
    }
    
    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Cache
    ) {
        var lineX = bounds.minX
        var lineY = bounds.minY
        var lineHeight: CGFloat = 0

        for index in subviews.indices {
            let itemSize = cache.sizes[index]
            let itemSpacing = lineX == bounds.minX ? 0 : spacing

            if lineX > bounds.minX && lineX + itemSpacing + itemSize.width > bounds.maxX {
                lineY += lineHeight + lineSpacing
                lineHeight = 0
                lineX = bounds.minX
            }

            if lineX > bounds.minX {
                lineX += spacing
            }

            let position = CGPoint(
                x: lineX + itemSize.width / 2,
                y: lineY + itemSize.height / 2
            )

            lineHeight = max(lineHeight, itemSize.height)
            lineX += itemSize.width

            subviews[index].place(
                at: position,
                anchor: .center,
                proposal: ProposedViewSize(itemSize)
            )
        }
    }
}
