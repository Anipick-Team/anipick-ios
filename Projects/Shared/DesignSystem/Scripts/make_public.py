"""Xcode가 만든 GeneratedAssetSymbols.swift를 public 심볼로 바꾼다 (generate_asset_symbols.sh가 부른다)."""
import re
import sys

source, destination = sys.argv[1], sys.argv[2]
text = open(source, encoding="utf-8").read()

# 값 타입 리소스는 Sendable이고 레거시 ViewModel 등 MainActor 밖에서도 쓰므로 nonisolated로 둔다
# (DesignSystem의 기본 격리는 MainActor).
text = re.sub(r"^    static (let|var) ", r"    nonisolated public static \1 ", text, flags=re.M)
text = text.replace("private let resourceBundle =", "nonisolated private let resourceBundle =")
# 표현식 하나인 게터에도 return을 쓴다 (레포 컨벤션 3.12)
text = re.sub(r"(static var \w+: [\w.]+ \{ )(?!return )", r"\1return ", text)
text = re.sub(r"^(        )(\.init\()", r"\1return \2", text, flags=re.M)

colors = re.findall(r'ColorResource\(name: "([^"]+)"', text)
images = re.findall(r'ImageResource\(name: "([^"]+)"', text)

def swift_array(names):
    return "[\n" + "".join(f'        "{name}",\n' for name in sorted(set(names))) + "    ]"

header = (
    "// 이 파일은 Scripts/generate_asset_symbols.sh가 만든다. 직접 고치지 않는다.\n"
    "// swift-format-ignore-file\n\n"
)
index = (
    "\n// MARK: - 테스트용 목록\n\n"
    "/// 카탈로그에 있는 에셋 이름. 모든 에셋이 번들에서 로드되는지 테스트에서 확인한다.\n"
    "enum AssetCatalogIndex {\n"
    f"    nonisolated static let colorNames: [String] = {swift_array(colors)}\n"
    f"    nonisolated static let imageNames: [String] = {swift_array(images)}\n"
    "}\n"
)
open(destination, "w", encoding="utf-8").write(header + text + index)
print(f"색 {len(set(colors))}개, 이미지 {len(set(images))}개 → {destination}")
