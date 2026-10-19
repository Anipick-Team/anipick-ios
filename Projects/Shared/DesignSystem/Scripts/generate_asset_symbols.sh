#!/bin/bash
# 에셋 카탈로그(Resources/*.xcassets)를 바꾸면 실행한다.
#
# Xcode가 만드는 에셋 심볼(ColorResource.anipickBlack, Image(.share) 등)은 internal이라 다른 모듈에서 보이지 않는다.
# Xcode가 만든 GeneratedAssetSymbols.swift를 public으로 바꿔 Sources/AssetSymbols.swift에 쓴다.
# 사용: Projects/Shared/DesignSystem/Scripts/generate_asset_symbols.sh  (tuist generate 이후)
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../../../.." && pwd)"
MODULE="$ROOT/Projects/Shared/DesignSystem"
DD="$(mktemp -d)"
trap 'rm -rf "$DD"' EXIT

# 모듈 설정은 자동 생성을 끄지만(이름 충돌), 여기서만 켜서 Xcode의 생성 결과를 얻는다.
# 레거시는 UIColor·Color·UIImage 확장(`.gray6` 등)도 쓰므로 확장 생성도 켠다 (앱 타깃 설정과 같게).
# AssetSymbols.swift와 이름이 겹쳐 컴파일은 실패할 수 있다 — 생성 파일은 컴파일 전에 만들어진다.
xcodebuild build -workspace "$ROOT/AniPick.xcworkspace" -scheme DesignSystem \
    -destination 'generic/platform=iOS Simulator' -derivedDataPath "$DD" \
    ASSETCATALOG_COMPILER_GENERATE_ASSET_SYMBOLS=YES \
    ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS=YES >/dev/null 2>&1 || true

GENERATED="$(find "$DD" -name GeneratedAssetSymbols.swift -path '*DesignSystem.build*' | head -1)"
if [ -z "$GENERATED" ]; then
    echo "GeneratedAssetSymbols.swift를 찾지 못했다" >&2
    exit 1
fi
python3 "$MODULE/Scripts/make_public.py" "$GENERATED" "$MODULE/Sources/AssetSymbols.swift"
