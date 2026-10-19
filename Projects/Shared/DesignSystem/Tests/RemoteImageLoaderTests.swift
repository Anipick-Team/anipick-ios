import Testing
import UIKit

@testable import DesignSystem

/// 크기를 정한 단색 PNG
private func pngData(width: Int, height: Int) -> Data {
    let format = UIGraphicsImageRendererFormat()
    format.scale = 1
    let renderer = UIGraphicsImageRenderer(
        size: CGSize(width: width, height: height), format: format)
    return renderer.pngData { context in
        UIColor.systemTeal.setFill()
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
    }
}

@Suite("이미지 다운샘플링")
struct ImageDownsamplerTests {
    @Test("긴 변을 maxPixelSize에 맞춰 비율대로 줄인다")
    func downsamplesToMaxPixelSize() async throws {
        let image = try await ImageDownsampler.downsample(
            pngData(width: 2000, height: 1000), maxPixelSize: 200)

        #expect(image.cgImage?.width == 200)
        #expect(image.cgImage?.height == 100)
    }

    @Test("이미지가 아닌 데이터는 invalidImageData")
    func rejectsInvalidData() async {
        await #expect(throws: RemoteImageError.invalidImageData) {
            try await ImageDownsampler.downsample(Data("not an image".utf8), maxPixelSize: 200)
        }
    }
}

@Suite("RemoteImageLoader", .timeLimit(.minutes(1)))
struct RemoteImageLoaderTests {
    private let server = ImageStubServer()

    @Test("같은 URL과 크기를 다시 요청하면 메모리 캐시에서 돌려준다")
    func servesFromMemoryCache() async throws {
        server.respond(body: pngData(width: 400, height: 400))
        let loader = RemoteImageLoader(session: server.session)

        let first = try await loader.image(for: server.url("a.png"), maxPixelSize: 100)
        let second = try await loader.image(for: server.url("a.png"), maxPixelSize: 100)

        #expect(server.requestCount == 1)
        #expect(first === second)
    }

    @Test("크기가 다르면 따로 받아 줄인다")
    func separatesCacheBySize() async throws {
        server.respond(body: pngData(width: 400, height: 400))
        let loader = RemoteImageLoader(session: server.session)

        let small = try await loader.image(for: server.url("a.png"), maxPixelSize: 100)
        let large = try await loader.image(for: server.url("a.png"), maxPixelSize: 300)

        #expect(server.requestCount == 2)
        #expect(small.cgImage?.width == 100)
        #expect(large.cgImage?.width == 300)
    }

    @Test("같은 키를 동시에 10번 요청해도 다운로드는 1번")
    func coalescesConcurrentRequests() async throws {
        server.respond(body: pngData(width: 400, height: 400), delay: .milliseconds(200))
        let loader = RemoteImageLoader(session: server.session)
        let url = server.url("a.png")

        let widths = try await withThrowingTaskGroup(of: Int?.self) { group in
            for _ in 0..<10 {
                group.addTask { try await loader.image(for: url, maxPixelSize: 100).cgImage?.width }
            }
            var widths: [Int?] = []
            for try await width in group {
                widths.append(width)
            }
            return widths
        }

        #expect(widths == Array(repeating: 100, count: 10))
        #expect(server.requestCount == 1)
    }

    @Test("HTTP 실패는 에러를 던지고 캐시하지 않는다")
    func doesNotCacheFailures() async throws {
        server.respond(status: 404, body: Data())
        let loader = RemoteImageLoader(session: server.session)
        let url = server.url("missing.png")

        await #expect(throws: RemoteImageError.http(status: 404)) {
            try await loader.image(for: url, maxPixelSize: 100)
        }
        server.respond(body: pngData(width: 400, height: 400))
        let image = try await loader.image(for: url, maxPixelSize: 100)

        #expect(server.requestCount == 2)
        #expect(image.cgImage?.width == 100)
    }
}
