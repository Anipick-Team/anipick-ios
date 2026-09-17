import PhotosUI
import SwiftUI
import UIKit

struct CommunityWriteView: View {
    let seriesId: Int
    let animeTitle: String

    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var content = ""
    @State private var isSpoiler = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var isRegistering = false
    @State private var titleError = false
    @State private var contentError = false

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
        .task(id: selectedPhoto) {
            guard let selectedPhoto else { return }
            do {
                selectedImageData = try await selectedPhoto.loadTransferable(type: Data.self)
                DLog("커뮤니티 이미지 선택 완료 - bytes: \(selectedImageData?.count ?? 0)")
            } catch {
                DLog("커뮤니티 이미지 선택 실패 - error: \(error.localizedDescription)")
            }
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
            Text("글 작성")
                .customFontStyle(size: 18, color: .anipickBlack, weight: .black)
            Spacer()

            Button(action: register) {
                Text(isRegistering ? "등록 중" : "등록")
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
        PhotosPicker(selection: $selectedPhoto, matching: .images) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray7)
                    .frame(width: 115, height: 105)

                if let data = selectedImageData, let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 115, height: 105)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    Image(systemName: "photo")
                        .font(.system(size: 23, weight: .medium))
                        .foregroundColor(.gray6)
                }
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

        guard !titleError, !contentError else {
            DLog("커뮤니티 글 등록 검증 실패 - titleEmpty: \(titleError), contentEmpty: \(contentError)")
            return
        }

        isRegistering = true
        Task {
            do {
                var imageIds: [Int] = []
                if let selectedImageData {
                    let response = try await CommunityAPIService.shared.uploadPostImage(
                        data: selectedImageData,
                        fileName: "community-post.jpg",
                        mimeType: "image/jpeg"
                    )
                    if let imageId = response.result?.imageId {
                        imageIds.append(imageId)
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
                let response = try await CommunityAPIService.shared.createPost(request)
                DLog("커뮤니티 글 등록 성공 - code: \(response.code), value: \(response.value)")
                await MainActor.run {
                    isRegistering = false
                    dismiss()
                }
            } catch {
                DLog("커뮤니티 글 등록 실패 - error: \(error.localizedDescription)")
                await MainActor.run { isRegistering = false }
            }
        }
    }
}
