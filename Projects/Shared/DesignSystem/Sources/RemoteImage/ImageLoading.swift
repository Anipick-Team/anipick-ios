import UIKit

/// URL의 이미지를 표시 크기에 맞게 줄여 돌려준다.
nonisolated public protocol ImageLoading: Sendable {
    /// - Parameter maxPixelSize: 긴 변의 최대 픽셀 수 (표시 크기 × 화면 배율)
    func image(for url: URL, maxPixelSize: Int) async throws -> UIImage
}

nonisolated public enum RemoteImageError: Error, Equatable, Sendable {
    /// HTTP 상태가 2xx가 아님
    case http(status: Int)
    /// 이미지로 읽을 수 없는 데이터
    case invalidImageData
}

/// 네트워크 없이 정해 둔 이미지를 돌려준다 (Example 앱·Preview용). `nil`이면 실패한다.
nonisolated public struct StaticImageLoader: ImageLoading {
    private let image: UIImage?

    public init(image: UIImage?) {
        self.image = image
    }

    public func image(for url: URL, maxPixelSize: Int) async throws -> UIImage {
        guard let image else {
            throw RemoteImageError.invalidImageData
        }
        return image
    }
}
