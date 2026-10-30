import SwiftUI
import UIKit

/// 배경이 투명한 여러 줄 입력. 글자 수를 넘기면 앞에서부터 잘라 낸다. 레거시 `ClearTextEditor`와 같은 동작이다.
public struct LimitedTextEditor: UIViewRepresentable {
    @Binding private var text: String
    private let characterLimit: Int

    public init(text: Binding<String>, characterLimit: Int = 200) {
        _text = text
        self.characterLimit = characterLimit
    }

    public func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.backgroundColor = .clear
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.textColor = .anipickBlack
        textView.delegate = context.coordinator
        return textView
    }

    public func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.text = text
    }

    public func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    public final class Coordinator: NSObject, UITextViewDelegate {
        private let parent: LimitedTextEditor

        init(_ parent: LimitedTextEditor) {
            self.parent = parent
        }

        public func textViewDidChange(_ textView: UITextView) {
            textView.text = LimitedTextEditor.truncated(textView.text, limit: parent.characterLimit)
            parent.text = textView.text
        }
    }

    nonisolated static func truncated(_ text: String, limit: Int) -> String {
        guard text.count > limit else {
            return text
        }
        return String(text.prefix(limit))
    }
}
