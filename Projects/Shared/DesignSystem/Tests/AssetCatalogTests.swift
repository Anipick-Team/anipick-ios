import SwiftUI
import Testing
import UIKit

@testable import DesignSystem

@Suite("에셋 카탈로그")
struct AssetCatalogTests {
    @Test("색 17개와 이미지 79개가 목록에 있다 (레거시 앱 카탈로그 + PR #18 infoIcon)")
    func indexMatchesLegacyCatalogs() {
        #expect(AssetCatalogIndex.colorNames.count == 17)
        #expect(AssetCatalogIndex.imageNames.count == 79)
    }

    @Test("모든 색을 DesignSystem 번들에서 찾는다")
    func loadsAllColors() {
        let missing = AssetCatalogIndex.colorNames.filter {
            UIColor(named: $0, in: .designSystem, compatibleWith: nil) == nil
        }
        #expect(missing.isEmpty)
    }

    @Test("모든 이미지를 DesignSystem 번들에서 찾는다")
    func loadsAllImages() {
        let missing = AssetCatalogIndex.imageNames.filter {
            UIImage(named: $0, in: .designSystem, with: nil) == nil
        }
        #expect(missing.isEmpty)
    }

    @Test("public 심볼이 DesignSystem 번들의 에셋을 가리킨다")
    func symbolsPointToDesignSystemBundle() {
        let named = UIColor(named: "AnipickPrimaryColor", in: .designSystem, compatibleWith: nil)
        #expect(UIColor.anipickPrimary == named)
        #expect(
            UIImage(resource: .share).pngData()
                == UIImage(named: "share", in: .designSystem, with: nil)?.pngData())
    }
}
