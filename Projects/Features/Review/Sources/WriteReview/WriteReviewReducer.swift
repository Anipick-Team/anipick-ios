import Analytics
import Foundation
import MVICore
import Navigation
import ReviewClientInterface

/// 리뷰 작성·수정. 동작 목록: notes/2026-10-29-R-review-01-write-review.md
struct WriteReviewReducer: Reducer {
    static let guidelineURL = URL(string: "https://anipick.p-e.kr/community-guidelines.html")!
    static let characterLimit = 200

    let reviewClient: any ReviewClient
    let navigator: any Navigator
    let analytics: any AnalyticsTracking
    let openURL: @MainActor @Sendable (URL) -> Void
    let onReviewWritten: @Sendable () async -> Void

    struct State: Equatable {
        let animeId: Int
        var rating: Double
        var content: String
        /// 수정이어도 꺼진 채로 시작한다 — 레거시가 기존 값을 받지 않는다 (V3, 발견 버그)
        var isSpoiler = false
        /// 처음 받은 내용이 있으면 수정 (V1)
        let isEditing: Bool

        init(animeId: Int, rating: Double, content: String) {
            self.animeId = animeId
            self.rating = rating
            self.content = content
            self.isEditing = !content.isEmpty
        }

        var title: String {
            return isEditing ? "리뷰 수정" : "리뷰 작성"
        }

        var submitTitle: String {
            return isEditing ? "리뷰 수정하기" : "리뷰 작성하기"
        }

        var counterText: String {
            return "\(content.count)/\(WriteReviewReducer.characterLimit)"
        }
    }

    enum Intent: Sendable {
        case ratingChanged(Double)
        case contentChanged(String)
        case spoilerTapped
        case guidelineTapped
        case submitTapped
        case backTapped
    }

    func reduce(into state: inout State, intent: Intent) -> Effect<Intent> {
        switch intent {
        case .ratingChanged(let rating):
            state.rating = rating
            return .none

        case .contentChanged(let content):
            state.content = content
            return .none

        case .spoilerTapped:
            state.isSpoiler.toggle()
            return .none

        case .guidelineTapped:
            return .run { [openURL] in
                await openURL(Self.guidelineURL)
                return nil
            }

        case .submitTapped:
            let review = (
                animeId: state.animeId, content: state.content, rating: state.rating,
                isSpoiler: state.isSpoiler
            )
            return .run { [reviewClient, analytics, onReviewWritten, navigator] in
                // 레거시처럼 응답을 기다리지 않고 닫는다 (V8). 화면이 닫히면 Store가 Effect를 취소하므로
                // 저장은 화면과 무관한 작업으로 보낸다 — 응답 뒤 기록·알림이 빠지지 않는다 (V9, 발견 버그)
                Task {
                    do {
                        try await reviewClient.writeReview(
                            animeId: review.animeId,
                            content: review.content,
                            rating: review.rating,
                            isSpoiler: review.isSpoiler
                        )
                        analytics.log(
                            .reviewWrite(
                                animeId: review.animeId,
                                rating: review.rating,
                                isSpoiler: review.isSpoiler
                            )
                        )
                        await onReviewWritten()
                    } catch {
                        analytics.logError(error, context: "patchReview")
                    }
                }
                await navigator.pop()
                return nil
            }

        case .backTapped:
            return .run { [navigator] in
                await navigator.pop()
                return nil
            }
        }
    }
}
