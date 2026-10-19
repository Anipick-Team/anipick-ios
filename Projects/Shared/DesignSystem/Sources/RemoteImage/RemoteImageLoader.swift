import Foundation
import UIKit

extension URLSession {
    /// 이미지 전용 세션. 디스크 캐시는 URLCache가 서버 캐시 헤더대로 맡는다.
    nonisolated public static let imageSession: URLSession = {
        let directory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appending(path: "RemoteImage", directoryHint: .isDirectory)
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = URLCache(
            memoryCapacity: 20 * 1024 * 1024,
            diskCapacity: 200 * 1024 * 1024,
            directory: directory
        )
        configuration.requestCachePolicy = .useProtocolCachePolicy
        return URLSession(configuration: configuration)
    }()
}

/// 원격 이미지를 받아 줄이고 메모리에 담아 둔다.
///
/// - 메모리 캐시: `URL + maxPixelSize` → 줄인 이미지 (`NSCache`, 메모리 부족 시 자동 비움)
/// - 같은 키를 동시에 요청하면 다운로드는 1번
/// - 실패는 캐시하지 않는다
public actor RemoteImageLoader: ImageLoading {
    public static let shared = RemoteImageLoader()

    private struct CacheKey: Hashable {
        let url: URL
        let maxPixelSize: Int

        var cacheKey: NSString {
            return "\(maxPixelSize)|\(url.absoluteString)" as NSString
        }
    }

    private let session: URLSession
    private let memory = NSCache<NSString, UIImage>()
    private var inFlight: [CacheKey: Task<UIImage, any Error>] = [:]

    public init(session: URLSession = .imageSession, memoryCountLimit: Int = 200) {
        self.session = session
        memory.countLimit = memoryCountLimit
    }

    public func image(for url: URL, maxPixelSize: Int) async throws -> UIImage {
        let key = CacheKey(url: url, maxPixelSize: maxPixelSize)
        if let cached = memory.object(forKey: key.cacheKey) {
            return cached
        }
        if let running = inFlight[key] {
            return try await running.value
        }

        let task = Task { [session] in
            return try await Self.fetch(url, maxPixelSize: maxPixelSize, session: session)
        }
        inFlight[key] = task
        defer { inFlight[key] = nil }

        let image = try await task.value
        memory.setObject(image, forKey: key.cacheKey)
        return image
    }

    @concurrent
    private static func fetch(
        _ url: URL,
        maxPixelSize: Int,
        session: URLSession
    ) async throws -> UIImage {
        let (data, response) = try await session.data(from: url)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw RemoteImageError.http(status: http.statusCode)
        }
        return try await ImageDownsampler.downsample(data, maxPixelSize: maxPixelSize)
    }
}
