//
//  ClearTextEditor.swift
//  AniPick
//
//  Created by cho on 7/5/25.
//


import SwiftUI

struct ClearTextEditor: UIViewRepresentable {
    @Binding var text: String
    var characterLimit: Int = 200
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.backgroundColor = .clear
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.textColor = .anipickBlack
        textView.delegate = context.coordinator
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.text = text
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UITextViewDelegate {
        var parent: ClearTextEditor

        init(_ parent: ClearTextEditor) {
            self.parent = parent
        }
        
        func textViewDidChange(_ textView: UITextView) {
            if textView.text.count > parent.characterLimit {
                textView.text = String(textView.text.prefix(parent.characterLimit))
            }
            parent.text = textView.text
        }
    }
}
