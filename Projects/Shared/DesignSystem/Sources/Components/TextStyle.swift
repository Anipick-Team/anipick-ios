import SwiftUI

extension View {
    /// 시스템 글꼴 크기·굵기와 글자색. 레거시 `customFontStyle(size:color:weight:)`와 같은 결과다.
    public func textStyle(size: CGFloat, color: Color, weight: Font.Weight? = nil) -> some View {
        return font(.system(size: size, weight: weight))
            .foregroundColor(color)
    }
}
