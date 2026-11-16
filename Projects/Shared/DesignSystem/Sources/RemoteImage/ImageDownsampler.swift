import ImageIO
import UIKit

/// 원본을 디코딩하지 않고 표시 크기로 줄인다 (WWDC18 "Image and Graphics Best Practices").
nonisolated enum ImageDownsampler {
    @concurrent
    static func downsample(
        _ data: Data,
        maxPixelSize: Int
    ) async throws(RemoteImageError) -> UIImage {
        let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithData(data as CFData, sourceOptions) else {
            throw .invalidImageData
        }
        let thumbnailOptions =
            [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceShouldCacheImmediately: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
            ] as CFDictionary
        guard
            let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, thumbnailOptions)
        else {
            throw .invalidImageData
        }
        return UIImage(cgImage: thumbnail)
    }
}
