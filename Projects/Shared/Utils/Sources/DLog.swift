import Foundation

/// 디버그 빌드에서만 `[파일:줄] 함수 ➜ 메시지`를 출력한다.
/// 이름은 레거시 호출부(앱 89개 파일)와 맞추려고 대문자로 시작한다.
// swift-format-ignore: AlwaysUseLowerCamelCase
public func DLog(
    _ message: Any,
    file: String = #file,
    function: String = #function,
    line: Int = #line
) {
    #if DEBUG
        let fileName = (file as NSString).lastPathComponent
        print("[\(fileName):\(line)] \(function) ➜ \(message)")
    #endif
}
