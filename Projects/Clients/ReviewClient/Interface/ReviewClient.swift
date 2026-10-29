import ClientCore

/// 리뷰 작성·수정 (레거시 `AnimeAPI.writeAndEditReview`).
public protocol ReviewClient: Sendable {
    /// 별점·스포일러·내용을 저장한다. 같은 애니에 다시 보내면 수정된다.
    ///
    /// 레거시는 응답 본문의 `code`를 보지 않고, 본문을 읽기만 하면 성공으로 처리한다(`WriteReviewViewModel.swift:47-57`).
    /// 그래서 이 함수도 전송·응답 해석에 실패할 때만 던진다.
    func writeReview(animeId: Int, content: String, rating: Double, isSpoiler: Bool)
        async throws(TransportError)
}
