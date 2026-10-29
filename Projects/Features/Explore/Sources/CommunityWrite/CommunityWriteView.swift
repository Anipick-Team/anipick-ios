import CommunityClientInterface
import DesignSystem
import MVICore
import PhotosUI
import SwiftUI
import UIKit
import UniformTypeIdentifiers

/// 레거시 `CommunityWriteView`와 같은 배치. 끌어서 순서 바꾸기 중인 사진 id는 제스처 상태라 View가 들고 있다.
struct CommunityWriteView: View {
    @State private var store: Store<CommunityWriteReducer>
    @State private var draggingImageID: UUID?
    private let imageURL: (Int) -> URL

    init(
        state: CommunityWriteReducer.State, reducer: CommunityWriteReducer,
        imageURL: @escaping (Int) -> URL
    ) {
        _store = State(initialValue: Store(initialState: state, reducer: reducer))
        self.imageURL = imageURL
    }

    private var state: CommunityWriteReducer.State {
        return store.state
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
                        if state.title.isEmpty {
                            Text("제목을 입력해 주세요.")
                                .font(.system(size: 15))
                                .foregroundColor(.gray4)
                                .allowsHitTesting(false)
                        }

                        TextField(
                            "",
                            text: Binding(
                                get: { store.state.title }, set: { store.send(.titleChanged($0)) })
                        )
                        .font(.system(size: 15))
                        .foregroundColor(.anipickBlack)
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 46)
                    .background(Color.gray7)
                    .cornerRadius(8)

                    if state.titleError {
                        Text("제목을 입력해 주세요.")
                            .font(.system(size: 13))
                            .foregroundColor(.pink)
                            .padding(.top, 8)
                    }

                    fieldTitle("내용")
                        .padding(.top, state.titleError ? 20 : 22)
                    contentEditor()

                    HStack(spacing: 8) {
                        Spacer()
                        Text("스포일러")
                            .font(.system(size: 14))
                            .foregroundColor(.anipickBlack)
                        Toggle(
                            "",
                            isOn: Binding(
                                get: { store.state.isSpoiler },
                                set: { store.send(.spoilerChanged($0)) })
                        )
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
                    #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        }
        .background(Color.white)
        .navigationBarHidden(true)
        .overlay(alignment: .bottom) {
            if let message = state.feedbackMessage {
                CommunityToast(message: message)
                    .padding(.bottom, 28)
            }
        }
    }

    private func header() -> some View {
        let isTitleBlank = state.isTitleBlank
        return HStack {
            Button {
                store.send(.backTapped)
            } label: {
                Image(.chevronLeft)
                    .resizable()
                    .frame(width: 24, height: 24)
            }

            Spacer()

            Text(state.postId == nil ? "글 작성" : "글 수정")
                .textStyle(size: 18, color: .anipickBlack, weight: .black)

            Spacer()

            Button {
                store.send(.registerTapped)
            } label: {
                Text(state.isRegistering ? "저장 중" : (state.postId == nil ? "등록" : "저장"))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isTitleBlank ? .gray6 : .white)
                    .frame(width: 50, height: 36)
                    .background(isTitleBlank ? Color.gray5 : Color.anipickPrimary)
                    .cornerRadius(5)
            }
            .disabled(state.isRegistering)
        }
        .padding(.horizontal, 20)
        .frame(height: 58)
        // 그림자를 헤더 배경에만 적용 (컨테이너에 걸면 등록·수정 버튼에도 그림자가 생김)
        .background(Color.white.shadow(.drop(color: .black.opacity(0.2), radius: 6, y: 2)))
    }

    private func fieldTitle(_ title: String) -> some View {
        return Text(title)
            .textStyle(size: 17, color: .anipickBlack, weight: .bold)
            .padding(.bottom, 12)
    }

    private func photoPicker() -> some View {
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                PhotosPicker(
                    selection: Binding(
                        get: { store.state.selectedPhotos }, set: { store.send(.photosPicked($0)) }),
                    maxSelectionCount: max(1, state.remainingPickerCount),
                    matching: .images
                ) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray7)
                            .frame(width: 115, height: 105)

                        Image(systemName: state.images.isEmpty ? "photo" : "plus")
                            .font(.system(size: 23, weight: .medium))
                            .foregroundColor(.gray6)
                    }
                }
                .disabled(state.remainingPickerCount == 0)

                if !state.images.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(state.images) { image in
                                thumbnail(image)
                            }
                        }
                    }
                }
            }

            if let imageError = state.imageError {
                Text(imageError)
                    .font(.system(size: 13))
                    .foregroundColor(.pink)
            }
        }
    }

    private func contentEditor() -> some View {
        return ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray7)
                .frame(height: 214)

            if state.content.isEmpty {
                Text("글 내용을 입력해 주세요.")
                    .font(.system(size: 15))
                    .foregroundColor(.gray4)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .allowsHitTesting(false)
            }

            TextEditor(
                text: Binding(
                    get: { store.state.content }, set: { store.send(.contentChanged($0)) })
            )
            .font(.system(size: 15))
            .foregroundColor(.anipickBlack)
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .padding(.horizontal, 11)
            .padding(.top, 8)
            .frame(height: 214)

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    // 숫자를 끼워 넣으면 "1,000"으로 표시되므로 한도는 글자로 둔다
                    Text("\(state.content.count)/1000")
                        .font(.system(size: 13))
                        .foregroundColor(.gray6)
                        .padding(.trailing, 16)
                        .padding(.bottom, 12)
                }
            }
            .frame(height: 214)
        }
    }

    private func thumbnail(_ image: CommunityWriteReducer.WriteImage) -> some View {
        return ZStack(alignment: .topTrailing) {
            Group {
                switch image.source {
                case .remote(let imageId):
                    ProtectedRemoteImage(url: imageURL(imageId))
                case .local(_, let preview, _):
                    Image(uiImage: preview)
                        .resizable()
                        .scaledToFill()
                }
            }
            .frame(width: 92, height: 82)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .onDrag {
                draggingImageID = image.id
                return NSItemProvider(object: image.id.uuidString as NSString)
            }
            .onDrop(
                of: [UTType.text],
                delegate: ImageDropDelegate(target: image.id, draggingImageID: $draggingImageID) {
                    store.send(.imageMoved(dragging: $0, onto: image.id))
                }
            )

            Button {
                store.send(.imageRemoved(image.id))
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.white)
                    .background(Color.black.opacity(0.45), in: Circle())
            }
            .padding(4)
        }
    }
}

/// 끌고 있는 사진이 다른 사진 위에 들어오면 그 자리로 옮긴다 (레거시 `CommunityImageDropDelegate`)
private struct ImageDropDelegate: DropDelegate {
    let target: UUID
    @Binding var draggingImageID: UUID?
    let move: (UUID) -> Void

    func dropEntered(info: DropInfo) {
        guard let draggingImageID, draggingImageID != target else {
            return
        }
        withAnimation {
            move(draggingImageID)
        }
    }

    func performDrop(info: DropInfo) -> Bool {
        draggingImageID = nil
        return true
    }
}

/// 화면 아래 안내 (레거시 `CommunityToast`)
struct CommunityToast: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(Color.black.opacity(0.82))
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.16), radius: 8, y: 3)
            .padding(.horizontal, 24)
    }
}
