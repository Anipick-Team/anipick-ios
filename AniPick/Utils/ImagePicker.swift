//
//  ImagePicker.swift
//  AniPick
//
//  Created by cho on 8/10/25.
//

import Alamofire
import SwiftUI

struct ImagePicker: UIViewControllerRepresentable {
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        var parent: ImagePicker
        private let session = NetworkSession.authenticated
        
        init(parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let selectedImage = info[.originalImage] as? UIImage {
                parent.selectedImage = selectedImage
                                
                let request = ProfileAPI.editProfileImage(image: selectedImage)
                let url = "http://anipick.p-e.kr:8080/api/image/profile-image"
                session.upload(multipartFormData: { multidata in
                    guard let imageData = selectedImage.jpegData(compressionQuality: 0.8) else {
                        DLog("Failed to convert image to data")
                        return
                    }
                    
                    multidata.append(imageData, withName: "profileImageFile", fileName: "profile.jpg", mimeType: "image/jpeg")
                }, to: url, method: request.method)
                .cURLDescription { description in
                    DLog("\(description)")
                }
                // TODO: 업로드 중이라는 작업 필요 -> 업로드 되고 나서 dismiss가 일어나야함
                .responseDecodable(of: ProfileImageResponse.self) { [weak self] response in
                    guard let self else { return }
                    switch response.result {
                    case .success(let data):
                        DLog("Image uploaded successfully: \(String(describing: data))")
                        UserDefaultsManager.shared.setImageId(imageId: data.result.imageId)
                        self.parent.presentationMode.wrappedValue.dismiss()
                    case .failure(let error):
                        DLog("Failed to upload image: \(error.localizedDescription)")
                        self.parent.presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            
          //  parent.presentationMode.wrappedValue.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }

    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) var presentationMode

    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.allowsEditing = false // 이미지 편집을 허용하지 않으면 false로 설정
        picker.sourceType = .photoLibrary // 갤러리에서 선택
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
}
