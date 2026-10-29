import ClientCore

/// 리뷰 작성·수정 (레거시 `AnimeAPI.writeAndEditReview`).
public protocol ReviewClient: Sendable {
    /// 별점·스포일러·내용을 저장한다. 같은 애니에 다시 보내면 수정된다.
    ///
    /// 레거시는 응답 본문의 `code`를 보지 않고, 본문을 읽기만 하면 성공으로 처리한다(`WriteReviewViewModel.swift:47-57`).
    /// 그래서 이 함수도 전송·응답 해석에 실패할 때만 던진다.
    func writeReview(animeId: Int, content: String, rating: Double, isSpoiler: Bool)
        async throws(TransportError)

    /// 내 리뷰 삭제 (`DELETE api/reviews/{id}`). 레거시처럼 응답 본문을 읽으면 성공이다(`code`를 보지 않음)
    func deleteReview(id: Int) async throws(TransportError)
    /// 가입 직후 취향 선택에서 매긴 별점을 한 번에 저장한다 (`POST api/reviews/bulk`). 응답 code는 보지 않는다
    func storeInitialRatings(_ ratings: [InitialRating]) async throws(TransportError)
}

/// 취향 선택의 별점 하나
public struct InitialRating: Equatable, Sendable {
    public let animeId: Int
    public let rating: Double

    public init(animeId: Int, rating: Double) {
        self.animeId = animeId
        self.rating = rating
    }
}
