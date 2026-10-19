import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.module(
    "DesignSystem",
    layer: .shared,
    isolation: .mainActor,
    hasResources: true,
    // Xcode가 만드는 에셋 심볼은 internal이라 레거시 앱에서 보이지 않는다.
    // 같은 이름의 public 심볼을 Sources/AssetSymbols.swift(Scripts/generate_asset_symbols.sh)로 대신 둔다.
    settings: ["ASSETCATALOG_COMPILER_GENERATE_ASSET_SYMBOLS": "NO"]
)
