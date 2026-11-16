import SwiftUI
import UIKit

/// 사진 앨범에서 한 장 고른다. 고르면 JPEG(품질 0.8)로 넘기고, 닫기는 부르는 쪽이 정한다 (레거시 `ImagePicker`)
struct ProfileImagePicker: UIViewControllerRepresentable {
    let onPicked: (Data) -> Void
    let onCancelled: () -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        picker.sourceType = .photoLibrary
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        return Coordinator(onPicked: onPicked, onCancelled: onCancelled)
    }

    final class Coordinator: NSObject, UINavigationControllerDelegate,
        UIImagePickerControllerDelegate
    {
        private let onPicked: (Data) -> Void
        private let onCancelled: () -> Void

        init(onPicked: @escaping (Data) -> Void, onCancelled: @escaping () -> Void) {
            self.onPicked = onPicked
            self.onCancelled = onCancelled
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            guard let image = info[.originalImage] as? UIImage else {
                return
            }
            // JPEG로 바꾸지 못하면 레거시처럼 빈 파일로 올린다
            onPicked(image.jpegData(compressionQuality: 0.8) ?? Data())
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onCancelled()
        }
    }
}
