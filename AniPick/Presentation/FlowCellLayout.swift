//
//  FlowLayout.swift
//  AniPick
//
//  Created by cho on 11/9/25.
//

import SwiftUI

struct FlowCellLayout: Layout {
    var spacing: CGFloat = 4
    var alignment: HorizontalAlignment = .leading  // ⭐ 정렬 옵션 추가

    struct Row {
        var subviews: [LayoutSubviews.Element] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    // MARK: - sizeThatFits
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = calculateRows(subviews: subviews, maxWidth: proposal.width ?? .infinity)
        let totalHeight = rows.reduce(0) { $0 + $1.height } + CGFloat(rows.count - 1) * spacing
        return CGSize(width: proposal.width ?? .infinity, height: totalHeight)
    }

    // MARK: - placeSubviews
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = calculateRows(subviews: subviews, maxWidth: bounds.width)
        var y = bounds.minY

        for row in rows {
            let rowTotalWidth = row.width
            let rowHeight = row.height

            // ⭐ 우측 정렬 계산
            let startX: CGFloat = {
                switch alignment {
                case .leading:
                    return bounds.minX
                case .trailing:
                    return bounds.maxX - rowTotalWidth
                default:
                    return bounds.minX
                }
            }()

            var x = startX

            for sub in row.subviews {
                let size = sub.sizeThatFits(.unspecified)
                sub.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }

            y += rowHeight + spacing
        }
    }

    // MARK: - Row 계산
    private func calculateRows(subviews: Subviews, maxWidth: CGFloat) -> [Row] {
        var rows: [Row] = []
        var currentRow = Row()

        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)

            if currentRow.width + size.width > maxWidth, !currentRow.subviews.isEmpty {
                rows.append(currentRow)
                currentRow = Row()
            }

            currentRow.subviews.append(sub)
            currentRow.width += size.width + spacing
            currentRow.height = max(currentRow.height, size.height)
        }

        if !currentRow.subviews.isEmpty {
            rows.append(currentRow)
        }

        return rows
    }
}

//struct FlowCellLayout: Layout {
//    var spacing: CGFloat = 4
//
//    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
//        var width: CGFloat = 0
//        var height: CGFloat = 0
//        let maxWidth = proposal.width ?? .infinity
//        
//        var rowHeight: CGFloat = 0
//
//        for view in subviews {
//            let size = view.sizeThatFits(.unspecified)
//            if width + size.width > maxWidth {
//                width = 0
//                height += rowHeight + spacing
//                rowHeight = 0
//            }
//            width += size.width + spacing
//            rowHeight = max(rowHeight, size.height)
//        }
//
//        return CGSize(width: maxWidth, height: height + rowHeight)
//    }
//
//    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
//        var x = bounds.minX
//        var y = bounds.minY
//        var rowHeight: CGFloat = 0
//
//        for view in subviews {
//            let size = view.sizeThatFits(.unspecified)
//
//            if x + size.width > bounds.maxX {
//                x = bounds.minX
//                y += rowHeight + spacing
//                rowHeight = 0
//            }
//
//            view.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
//            x += size.width + spacing
//            rowHeight = max(rowHeight, size.height)
//        }
//    }
//}

struct FlowLayoutProducer: Layout {
    var alignment: HorizontalAlignment = .leading
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing,
            alignment: alignment
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing,
            alignment: alignment
        )
        
        for (index, subview) in subviews.enumerated() {
            subview.place(at: result.positions[index], proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat, alignment: HorizontalAlignment) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var rowHeight: CGFloat = 0
            var rowItems: [(subview: LayoutSubview, size: CGSize)] = []
            
            func finishRow(at y: CGFloat) {
                guard !rowItems.isEmpty else { return }
                
                let rowWidth = rowItems.reduce(0) { $0 + $1.size.width } + CGFloat(rowItems.count - 1) * spacing
                var x: CGFloat
                
                switch alignment {
                case .trailing:
                    x = maxWidth - rowWidth
                case .center:
                    x = (maxWidth - rowWidth) / 2
                default:
                    x = 0
                }
                
                for (subview, size) in rowItems {
                    positions.append(CGPoint(x: x, y: y))
                    x += size.width + spacing
                }
                
                rowItems.removeAll()
            }
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if currentX + size.width > maxWidth && currentX > 0 {
                    finishRow(at: currentY)
                    currentY += rowHeight + spacing
                    currentX = 0
                    rowHeight = 0
                }
                
                rowItems.append((subview, size))
                currentX += size.width + spacing
                rowHeight = max(rowHeight, size.height)
            }
            
            finishRow(at: currentY)
            
            self.size = CGSize(width: maxWidth, height: currentY + rowHeight)
        }
    }
}


