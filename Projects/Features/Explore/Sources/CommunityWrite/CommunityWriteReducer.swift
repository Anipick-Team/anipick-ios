import CommunityClientInterface
import Foundation
import MVICore
import Navigation
import PhotosUI
import SwiftUI
import UIKit

/// 커뮤니티 글 작성·수정. 동작 목록: notes/2026-10-30-R-explore-03-community-write.md (CW1~CW16)
struct CommunityWriteReducer: Reducer {
    static let maxImageCount = 5
    static let titleLimit = 50
    static let contentLimit = 1000
    static let failureMessage = "게시글을 저장하지 못했어요. 다시 시도해 주세요."

    let communityClient: any CommunityClient
    let navigator: any Navigator
    /// 고른 사진의 원본 데이터 (실패하면 nil)
    let loadPhoto: @Sendable (PhotosPickerItem) async -> Data?
    /// 수정을 저장하면 App에 알린다 (레거시 `.communityPostUpdated` 알림)
    let postUpdated: @MainActor (Int) -> Void
    var maxImageBytes = 10 * 1024 * 1024
    var feedbackDuration: Duration = .milliseconds(1500)
    var dismissDelay: Duration = .milliseconds(900)

    nonisolated struct WriteImage: Identifiable, Equatable, Sendable {
        enum Source: Equatable, Sendable {
            /// 이미 서버에 올라간 사진 (수정 진입 시)
            case remote(imageId: Int)
            /// 이번에 고른 사진 (JPEG 품질 0.85)
            case local(jpeg: Data, preview: UIImage, pickerItem: PhotosPickerItem)
        }

        let id: UUID
        let source: Source

        init(id: UUID = UUID(), source: Source) {
            self.id = id
            self.source = source
        }

        var pickerItem: PhotosPickerItem? {
            guard case .local(_, _, let pickerItem) = source else {
                return nil
            }
            return pickerItem
        }
    }

    struct State: Equatable {
        let seriesId: Int
        /// nil이면 새 글
        let postId: Int?
        var title: String
        var content: String
        var isSpoiler: Bool
        var images: [WriteImage]
        var selectedPhotos: [PhotosPickerItem] = []
        var isRegistering = false
        var titleError = false
        var imageError: String?
        var feedbackMessage: String?

        init(
            seriesId: Int, postId: Int? = nil, title: String = "", content: String = "",
            isSpoiler: Bool = false, imageIds: [Int] = []
        ) {
            self.seriesId = seriesId
            self.postId = postId
            self.title = title
            self.content = content
            self.isSpoiler = isSpoiler
            images = imageIds.map { WriteImage(source: .remote(imageId: $0)) }
        }

        /// 사진 선택 창에서 더 고를 수 있는 장수 (전체 한도 - 서버에 있는 사진)
        var remainingPickerCount: Int {
            return max(
                0,
                CommunityWriteReducer.maxImageCount - images.filter { $0.pickerItem == nil }.count)
        }

        var isTitleBlank: Bool {
            return title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    enum SaveResult: Equatable, Sendable {
        case saved
        case rejected(String?)
        case failed
    }

    enum Intent: Sendable {
        case titleChanged(String)
        case contentChanged(String)
        case spoilerChanged(Bool)
        case photosPicked([PhotosPickerItem])
        case photosLoaded(
            picked: [PhotosPickerItem], loaded: [WriteImage], failed: Int, oversized: Bool)
        case imageRemoved(UUID)
        case imageMoved(dragging: UUID, onto: UUID)
        case registerTapped
        case saveFinished(SaveResult)
        case feedbackExpired(String)
        case dismissAfterSave
        case backTapped
    }

    func reduce(into state: inout State, intent: Intent) -> Effect<Intent> {
        switch intent {
        case .titleChanged(let title):
            state.title = String(title.prefix(Self.titleLimit))
            state.titleError = false
            return .none

        case .contentChanged(let content):
            state.content = String(content.prefix(Self.contentLimit))
            return .none

        case .spoilerChanged(let isSpoiler):
            state.isSpoiler = isSpoiler
            return .none

        case .photosPicked(let photos):
            return pick(&state, photos)

        case .photosLoaded(let picked, let loaded, let failed, let oversized):
            if oversized {
                state.imageError = "사진 1장당 최대 10MB까지 첨부할 수 있어요."
            }
            // 서버 사진과 아직 선택된 사진은 순서를 지키고, 새로 불러온 사진을 뒤에 붙인다
            let kept = state.images.filter { image in
                guard let pickerItem = image.pickerItem else {
                    return true
                }
                return picked.contains(pickerItem)
            }
            state.images = kept + loaded
            if failed == 0 {
                state.imageError = nil
            }
            return .none

        case .imageRemoved(let id):
            guard let image = state.images.first(where: { $0.id == id }) else {
                return .none
            }
            state.images.removeAll { $0.id == id }
            guard let pickerItem = image.pickerItem else {
                return .none
            }
            // 레거시: 선택 목록이 바뀌면 다시 불러오기가 돈다 (새 사진이 없으니 정리만 한다)
            return pick(&state, state.selectedPhotos.filter { $0 != pickerItem })

        case .imageMoved(let dragging, let target):
            guard dragging != target,
                let from = state.images.firstIndex(where: { $0.id == dragging }),
                let to = state.images.firstIndex(where: { $0.id == target })
            else {
                return .none
            }
            state.images.move(
                fromOffsets: IndexSet(integer: from), toOffset: to > from ? to + 1 : to)
            return .none

        case .registerTapped:
            // 연속 탭은 여기서 막는다 (PR #17)
            guard !state.isRegistering else {
                return .none
            }
            let title = state.title.trimmingCharacters(in: .whitespacesAndNewlines)
            // 내용은 0자 허용, 공백만 있으면 빈 문자열로 보낸다 (PR #16)
            let content = state.content.trimmingCharacters(in: .whitespacesAndNewlines)
            state.titleError = title.isEmpty
            guard !state.titleError, state.imageError == nil else {
                return .none
            }
            state.isRegistering = true
            return save(
                seriesId: state.seriesId, postId: state.postId, title: title, content: content,
                isSpoiler: state.isSpoiler, images: state.images)

        case .saveFinished(let result):
            switch result {
            case .saved:
                // 화면이 닫힐 때까지 isRegistering을 유지해 같은 글이 다시 등록되지 않게 한다 (PR #17)
                let message = state.postId == nil ? "게시글이 등록되었습니다." : "게시글이 수정되었습니다."
                let feedback = showFeedback(&state, message)
                if let postId = state.postId {
                    postUpdated(postId)
                }
                let dismiss: Effect<Intent> = .run { [dismissDelay] in
                    try? await Task.sleep(for: dismissDelay)
                    return .dismissAfterSave
                }
                return .merge([feedback, dismiss])
            case .rejected(let message):
                state.isRegistering = false
                return showFeedback(&state, message ?? Self.failureMessage)
            case .failed:
                state.isRegistering = false
                return showFeedback(&state, Self.failureMessage)
            }

        case .feedbackExpired(let message):
            if state.feedbackMessage == message {
                state.feedbackMessage = nil
            }
            return .none

        case .dismissAfterSave, .backTapped:
            return .run { [navigator] in
                await navigator.pop()
                return nil
            }
        }
    }

    /// 레거시 `loadSelectedImages`: 한도를 넘으면 안내하고 앞의 것만 남긴다. 새로 고른 사진만 불러온다
    private func pick(_ state: inout State, _ photos: [PhotosPickerItem]) -> Effect<Intent> {
        var photos = photos
        let limit = state.remainingPickerCount
        if photos.count > limit {
            state.imageError = "사진은 최대 \(Self.maxImageCount)장까지 첨부할 수 있어요."
            photos = Array(photos.prefix(limit))
        }
        state.selectedPhotos = photos
        let alreadyLoaded = state.images.compactMap(\.pickerItem)
        let newPhotos = photos.filter { !alreadyLoaded.contains($0) }
        return .run { [loadPhoto, maxImageBytes, photos] in
            var loaded: [WriteImage] = []
            var failed = 0
            var oversized = false
            for photo in newPhotos {
                guard let data = await loadPhoto(photo),
                    let image = UIImage(data: data),
                    let jpeg = image.jpegData(compressionQuality: 0.85)
                else {
                    failed += 1
                    continue
                }
                guard jpeg.count <= maxImageBytes else {
                    failed += 1
                    oversized = true
                    continue
                }
                loaded.append(
                    WriteImage(source: .local(jpeg: jpeg, preview: image, pickerItem: photo)))
            }
            return .photosLoaded(
                picked: photos, loaded: loaded, failed: failed, oversized: oversized)
        }
    }

    /// 안내 문구는 처음 뜰 때부터 1.5초 뒤 사라진다 (이미 떠 있으면 문구만 바뀌고 타이머는 그대로)
    private func showFeedback(_ state: inout State, _ message: String) -> Effect<Intent> {
        let wasHidden = state.feedbackMessage == nil
        state.feedbackMessage = message
        guard wasHidden else {
            return .none
        }
        return .run { [feedbackDuration] in
            try? await Task.sleep(for: feedbackDuration)
            return .feedbackExpired(message)
        }
    }

    /// 화면 순서대로: 서버 사진은 id를 그대로, 새 사진만 올린 뒤 저장한다.
    /// 화면을 떠나도 저장은 끝까지 간다 (레거시 Task와 같음)
    private func save(
        seriesId: Int, postId: Int?, title: String, content: String, isSpoiler: Bool,
        images: [WriteImage]
    ) -> Effect<Intent> {
        return .run { [communityClient] in
            let result = await Task { () -> SaveResult in
                do {
                    var imageIds: [Int] = []
                    for (index, image) in images.enumerated() {
                        switch image.source {
                        case .remote(let imageId):
                            imageIds.append(imageId)
                        case .local(let jpeg, _, _):
                            if let imageId = try await communityClient.uploadPostImage(
                                jpeg: jpeg, fileName: "community-post-\(index + 1).jpg")
                            {
                                imageIds.append(imageId)
                            }
                        }
                    }
                    let draft = PostDraft(
                        title: title, content: content, isSpoiler: isSpoiler, imageIds: imageIds)
                    let outcome =
                        if let postId {
                            try await communityClient.updatePost(id: postId, draft)
                        } else {
                            try await communityClient.createPost(seriesId: seriesId, draft)
                        }
                    switch outcome {
                    case .saved:
                        return .saved
                    case .rejected(let message):
                        return .rejected(message)
                    }
                } catch {
                    return .failed
                }
            }.value
            return .saveFinished(result)
        }
    }
}
