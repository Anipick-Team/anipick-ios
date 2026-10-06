import PhotosUI
import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct CommunityWriteView: View {
    let seriesId: Int
    let animeTitle: String
    let postId: Int?
    let initialImageIds: [Int]

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
        self.initialImageIds = initialImageIds
        _title = State(initialValue: initialTitle)
        _content = State(initialValue: initialContent)
        _isSpoiler = State(initialValue: initialIsSpoiler)
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
                    TextField("제목을 입력해 주세요.", text: $title)
                        .font(.system(size: 15))
                        .foregroundColor(.anipickBlack)
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
        .background(Color.white)
        .shadow(color: .black.opacity(0.12), radius: 5, y: 3)
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
                PhotosPicker(selection: $selectedPhotos, maxSelectionCount: maxImageCount, matching: .images) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray7)
                            .frame(width: 115, height: 105)
                        Image(systemName: selectedImages.isEmpty ? "photo" : "plus")
                            .font(.system(size: 23, weight: .medium))
                            .foregroundColor(.gray6)
                    }
                }

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
                    .foregroundColor(.gray6)
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
                var imageIds = initialImageIds
                if !selectedImages.isEmpty {
                    imageIds.removeAll()
                    for (index, image) in selectedImages.enumerated() {
                        let response = try await CommunityAPIService.shared.uploadPostImage(
                            data: image.data,
                            fileName: "community-post-\(index + 1).jpg",
                            mimeType: "image/jpeg"
                        )
                        if let imageId = response.result?.imageId {
                            imageIds.append(imageId)
                        }
                    }
                    DLog("커뮤니티 이미지 업로드 성공 - imageIds: \(imageIds)")
                }

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
                DLog("커뮤니티 글 등록 성공 - code: \(response.code), value: \(response.value)")
                await MainActor.run {
                    isRegistering = false
                    feedbackMessage = postId == nil ? "게시글이 등록되었습니다." : "게시글이 수정되었습니다."
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                        dismiss()
                    }
                }
            } catch {
                DLog("커뮤니티 글 등록 실패 - error: \(error.localizedDescription)")
                await MainActor.run { isRegistering = false }
            }
        }
    }

    @ViewBuilder
    private func imageThumbnail(_ item: CommunityWriteImage) -> some View {
        ZStack(alignment: .topTrailing) {
            Image(uiImage: item.image)
                .resizable()
                .scaledToFill()
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
                selectedPhotos.removeAll()
                DLog("커뮤니티 이미지 삭제 - imageId: \(item.id.uuidString)")
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.white)
                    .background(Color.black.opacity(0.45), in: Circle())
            }
            .padding(4)
        }
    }

    private func loadSelectedImages(_ photos: [PhotosPickerItem]) async {
        guard photos.count <= maxImageCount else {
            await MainActor.run {
                imageError = "사진은 최대 \(maxImageCount)장까지 첨부할 수 있어요."
                selectedPhotos = Array(photos.prefix(maxImageCount))
            }
            return
        }

        var loadedImages: [CommunityWriteImage] = []
        for photo in photos {
            do {
                guard let data = try await photo.loadTransferable(type: Data.self),
                      let image = UIImage(data: data),
                      let compressedData = image.jpegData(compressionQuality: 0.85) else { continue }
                guard compressedData.count <= maxImageBytes else {
                    await MainActor.run { imageError = "사진 1장당 최대 10MB까지 첨부할 수 있어요." }
                    continue
                }
                loadedImages.append(CommunityWriteImage(data: compressedData, image: image))
            } catch {
                DLog("커뮤니티 이미지 선택 실패 - error: \(error.localizedDescription)")
            }
        }

        await MainActor.run {
            selectedImages = loadedImages
            if loadedImages.count == photos.count { imageError = nil }
            DLog("커뮤니티 이미지 선택 완료 - count: \(loadedImages.count)")
        }
    }
}

private struct CommunityWriteImage: Identifiable {
    let id = UUID()
    let data: Data
    let image: UIImage
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
