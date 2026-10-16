import PhotosUI
import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct CommunityWriteView: View {
    let seriesId: Int
    let animeTitle: String
    let postId: Int?

    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var content: String
    @State private var isSpoiler: Bool
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var selectedImages: [CommunityWriteImage] = []
    @State private var draggingImageID: UUID?
    @State private var isRegistering = false
    @State private var titleError = false
    @State private var contentError = false
    @State private var imageError: String?
    @State private var feedbackMessage: String?

    private let maxImageCount = 5
    private let maxImageBytes = 10 * 1024 * 1024

    init(seriesId: Int, animeTitle: String, postId: Int? = nil, initialTitle: String = "", initialContent: String = "", initialIsSpoiler: Bool = false, initialImageIds: [Int] = []) {
        self.seriesId = seriesId
        self.animeTitle = animeTitle
        self.postId = postId
        _title = State(initialValue: initialTitle)
        _content = State(initialValue: initialContent)
        _isSpoiler = State(initialValue: initialIsSpoiler)
        // 수정 진입 시 기존 첨부 사진을 편집 목록에 채운다
        _selectedImages = State(initialValue: initialImageIds.map { CommunityWriteImage(source: .remote(imageId: $0)) })
    }

    /// 이미 서버에 있는 사진 수. PhotosPicker로 고를 수 있는 장수는 전체 한도에서 이만큼 뺀다.
    private var remoteImageCount: Int {
        return selectedImages.filter { $0.pickerItem == nil }.count
    }

    private var remainingPickerCount: Int {
        return max(0, maxImageCount - remoteImageCount)
    }

    var body: some View {
        VStack(spacing: 0) {
            header()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    fieldTitle("사진")
                    photoPicker()

                    fieldTitle("제목")
                        .padding(.top, 22)
                    ZStack(alignment: .leading) {
                        if title.isEmpty {
                            Text("제목을 입력해 주세요.")
                                .font(.system(size: 15))
                                .foregroundColor(.gray4)
                                .allowsHitTesting(false)
                        }
                        TextField("", text: $title)
                            .font(.system(size: 15))
                            .foregroundColor(.anipickBlack)
                    }
                        .padding(.horizontal, 16)
                        .frame(height: 46)
                        .background(Color.gray7)
                        .cornerRadius(8)
                        .onChange(of: title) { value in
                            if value.count > 50 { title = String(value.prefix(50)) }
                            titleError = false
                        }

                    if titleError {
                        Text("제목을 입력해 주세요.")
                            .font(.system(size: 13))
                            .foregroundColor(.pink)
                            .padding(.top, 8)
                    }

                    fieldTitle("내용")
                        .padding(.top, titleError ? 20 : 22)
            contentEditor()
            if contentError {
                Text("내용을 입력해 주세요.")
                    .font(.system(size: 13))
                    .foregroundColor(.pink)
                    .padding(.top, 8)
            }

            HStack(spacing: 8) {
                        Spacer()
                        Text("스포일러")
                            .font(.system(size: 14))
                            .foregroundColor(.anipickBlack)
                        Toggle("", isOn: $isSpoiler)
                            .labelsHidden()
                            .tint(.anipickPrimary)
                            .scaleEffect(0.8)
                    }
                    .padding(.top, 16)
                }
                .padding(.horizontal, 20)
                .padding(.top, 28)
                .padding(.bottom, 30)
            }
            .scrollDismissesKeyboard(.interactively)
            .contentShape(Rectangle())
            .onTapGesture {
                UIApplication.shared.sendAction(
                    #selector(UIResponder.resignFirstResponder),
                    to: nil,
                    from: nil,
                    for: nil
                )
            }
        }
        .background(Color.white)
        .navigationBarHidden(true)
        .overlay(alignment: .bottom) {
            if let feedbackMessage {
                CommunityToast(message: feedbackMessage)
                    .padding(.bottom, 28)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            if self.feedbackMessage == feedbackMessage {
                                self.feedbackMessage = nil
                            }
                        }
                    }
            }
        }
        .onChange(of: selectedPhotos) { photos in
            Task { await loadSelectedImages(photos) }
        }
    }

    @ViewBuilder
    private func header() -> some View {
        HStack {
            Button { dismiss() } label: {
                Image(.chevronLeft)
                    .resizable()
                    .frame(width: 24, height: 24)
            }

            Spacer()
            Text(postId == nil ? "글 작성" : "글 수정")
                .customFontStyle(size: 18, color: .anipickBlack, weight: .black)
            Spacer()

            Button(action: register) {
                Text(isRegistering ? "저장 중" : (postId == nil ? "등록" : "저장"))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray6 : .white)
                    .frame(width: 50, height: 36)
                    .background(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray5 : Color.anipickPrimary)
                    .cornerRadius(5)
            }
            .disabled(isRegistering)
        }
        .padding(.horizontal, 20)
        .frame(height: 58)
        // 그림자를 헤더 배경에만 적용 (컨테이너에 걸면 등록·수정 버튼에도 그림자가 생김)
        .background(Color.white.shadow(.drop(color: .black.opacity(0.2), radius: 6, y: 2)))
    }

    @ViewBuilder
    private func fieldTitle(_ title: String) -> some View {
        Text(title)
            .customFontStyle(size: 17, color: .anipickBlack, weight: .bold)
            .padding(.bottom, 12)
    }

    @ViewBuilder
    private func photoPicker() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                PhotosPicker(selection: $selectedPhotos, maxSelectionCount: max(1, remainingPickerCount), matching: .images) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray7)
                            .frame(width: 115, height: 105)
                        Image(systemName: selectedImages.isEmpty ? "photo" : "plus")
                            .font(.system(size: 23, weight: .medium))
                            .foregroundColor(.gray6)
                    }
                }
                .disabled(remainingPickerCount == 0)

                if !selectedImages.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(selectedImages) { item in
                                imageThumbnail(item)
                            }
                        }
                    }
                }
            }

            if let imageError {
                Text(imageError)
                    .font(.system(size: 13))
                    .foregroundColor(.pink)
            }
        }
    }

    @ViewBuilder
    private func contentEditor() -> some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray7)
                .frame(height: 214)

            if content.isEmpty {
                Text("글 내용을 입력해 주세요.")
                    .font(.system(size: 15))
                    .foregroundColor(.gray4)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .allowsHitTesting(false)
            }

            TextEditor(text: $content)
                .font(.system(size: 15))
                .foregroundColor(.anipickBlack)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .padding(.horizontal, 11)
                .padding(.top, 8)
                .frame(height: 214)
                .onChange(of: content) { value in
                    if value.count > 1000 { content = String(value.prefix(1000)) }
                    contentError = false
                }

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Text("\(content.count)/1000")
                        .font(.system(size: 13))
                        .foregroundColor(.gray6)
                        .padding(.trailing, 16)
                        .padding(.bottom, 12)
                }
            }
            .frame(height: 214)
        }
    }

    private func register() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        titleError = trimmedTitle.isEmpty
        contentError = trimmedContent.isEmpty

        guard !titleError, !contentError, imageError == nil else {
            DLog("커뮤니티 글 등록 검증 실패 - titleEmpty: \(titleError), contentEmpty: \(contentError), imageError: \(imageError ?? "없음")")
            return
        }

        isRegistering = true
        Task {
            do {
                // 화면 순서대로: 기존 사진은 id를 그대로 쓰고 새로 고른 사진만 업로드한다
                // (서버는 수정 시 첨부 사진을 전량 교체)
                var imageIds: [Int] = []
                for (index, image) in selectedImages.enumerated() {
                    switch image.source {
                    case .remote(let imageId):
                        imageIds.append(imageId)
                    case .local(let data, _, _):
                        let response = try await CommunityAPIService.shared.uploadPostImage(
                            data: data,
                            fileName: "community-post-\(index + 1).jpg",
                            mimeType: "image/jpeg"
                        )
                        if let imageId = response.result?.imageId {
                            imageIds.append(imageId)
                        }
                    }
                }
                DLog("커뮤니티 이미지 준비 완료 - imageIds: \(imageIds)")

                let request = CommunityPostRequest(
                    seriesId: seriesId,
                    title: trimmedTitle,
                    content: trimmedContent,
                    isSpoiler: isSpoiler,
                    imageIds: imageIds.isEmpty ? nil : imageIds
                )
                let response: BaseResponse
                if let postId {
                    response = try await CommunityAPIService.shared.updatePost(postId: postId, body: request)
                } else {
                    response = try await CommunityAPIService.shared.createPost(request)
                }
                // 서버는 비즈니스 오류도 HTTP 200으로 내려주므로 code로 성공 여부를 가른다
                guard response.code == 200 else {
                    DLog("커뮤니티 글 등록 실패 - code: \(response.code), errorValue: \(response.errorValue ?? "")")
                    await MainActor.run {
                        isRegistering = false
                        feedbackMessage = response.errorValue ?? "게시글을 저장하지 못했어요. 다시 시도해 주세요."
                    }
                    return
                }
                DLog("커뮤니티 글 등록 성공 - code: \(response.code), value: \(response.value)")
                await MainActor.run {
                    isRegistering = false
                    feedbackMessage = postId == nil ? "게시글이 등록되었습니다." : "게시글이 수정되었습니다."
                    if let postId {
                        NotificationCenter.default.post(name: .communityPostUpdated, object: nil, userInfo: ["postId": postId])
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                        dismiss()
                    }
                }
            } catch {
                DLog("커뮤니티 글 등록 실패 - error: \(error.localizedDescription)")
                await MainActor.run {
                    isRegistering = false
                    feedbackMessage = "게시글을 저장하지 못했어요. 다시 시도해 주세요."
                }
            }
        }
    }

    @ViewBuilder
    private func imageThumbnail(_ item: CommunityWriteImage) -> some View {
        ZStack(alignment: .topTrailing) {
            Group {
                switch item.source {
                case .remote(let imageId):
                    CommunityRemoteImage(urlString: "\(NetworkManager.baseUrl)api/image/\(imageId)")
                case .local(_, let image, _):
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                }
            }
                .frame(width: 92, height: 82)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .onDrag {
                    draggingImageID = item.id
                    return NSItemProvider(object: item.id.uuidString as NSString)
                }
                .onDrop(
                    of: [UTType.text],
                    delegate: CommunityImageDropDelegate(
                        item: item,
                        images: $selectedImages,
                        draggingImageID: $draggingImageID
                    )
                )

            Button {
                selectedImages.removeAll { $0.id == item.id }
                if let pickerItem = item.pickerItem {
                    selectedPhotos.removeAll { $0 == pickerItem }
                }
                DLog("커뮤니티 이미지 삭제 - imageId: \(item.id.uuidString)")
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.white)
                    .background(Color.black.opacity(0.45), in: Circle())
            }
            .padding(4)
        }
    }

    /// PhotosPicker 선택 결과를 편집 목록에 반영한다.
    /// 기존(서버) 사진과 이미 불러온 로컬 사진은 순서를 유지하고, 새로 고른 사진만 불러와 뒤에 붙인다.
    private func loadSelectedImages(_ photos: [PhotosPickerItem]) async {
        let limit = remainingPickerCount
        guard photos.count <= limit else {
            await MainActor.run {
                imageError = "사진은 최대 \(maxImageCount)장까지 첨부할 수 있어요."
                selectedPhotos = Array(photos.prefix(limit))
            }
            return
        }

        let alreadyLoaded = selectedImages.compactMap(\.pickerItem)
        var newImages: [CommunityWriteImage] = []
        var failedCount = 0
        for photo in photos where !alreadyLoaded.contains(photo) {
            do {
                guard let data = try await photo.loadTransferable(type: Data.self),
                      let image = UIImage(data: data),
                      let compressedData = image.jpegData(compressionQuality: 0.85) else {
                    failedCount += 1
                    continue
                }
                guard compressedData.count <= maxImageBytes else {
                    failedCount += 1
                    await MainActor.run { imageError = "사진 1장당 최대 10MB까지 첨부할 수 있어요." }
                    continue
                }
                newImages.append(CommunityWriteImage(source: .local(data: compressedData, image: image, pickerItem: photo)))
            } catch {
                failedCount += 1
                DLog("커뮤니티 이미지 선택 실패 - error: \(error.localizedDescription)")
            }
        }

        await MainActor.run {
            let kept = selectedImages.filter { item in
                guard let pickerItem = item.pickerItem else { return true }
                return photos.contains(pickerItem)
            }
            selectedImages = kept + newImages
            if failedCount == 0 { imageError = nil }
            DLog("커뮤니티 이미지 선택 완료 - count: \(selectedImages.count)")
        }
    }
}

private struct CommunityWriteImage: Identifiable {
    enum Source {
        /// 이미 서버에 올라간 사진 (수정 진입 시)
        case remote(imageId: Int)
        /// 이번에 PhotosPicker로 고른 사진
        case local(data: Data, image: UIImage, pickerItem: PhotosPickerItem)
    }

    let id = UUID()
    let source: Source

    var pickerItem: PhotosPickerItem? {
        guard case let .local(_, _, pickerItem) = source else { return nil }
        return pickerItem
    }
}

private struct CommunityImageDropDelegate: DropDelegate {
    let item: CommunityWriteImage
    @Binding var images: [CommunityWriteImage]
    @Binding var draggingImageID: UUID?

    func dropEntered(info: DropInfo) {
        guard let draggingImageID,
              draggingImageID != item.id,
              let fromIndex = images.firstIndex(where: { $0.id == draggingImageID }),
              let toIndex = images.firstIndex(where: { $0.id == item.id }) else { return }

        withAnimation {
            images.move(
                fromOffsets: IndexSet(integer: fromIndex),
                toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex
            )
        }
    }

    func performDrop(info: DropInfo) -> Bool {
        draggingImageID = nil
        return true
    }
}
