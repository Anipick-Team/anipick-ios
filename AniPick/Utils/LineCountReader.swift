//
//  LineCountReader.swift
//  AniPick
//
//  Created by cho on 11/27/25.
//

import UIKit
import SwiftUI

struct LineCountReader: ViewModifier {
    @Binding var lineCount: Int
    
    func body(content: Content) -> some View {
        content
            .background(
                TextLineCounter(lineCount: $lineCount)
                    .opacity(0)
            )
    }
}

extension View {
    func readLineCount(_ lineCount: Binding<Int>) -> some View {
        self.modifier(LineCountReader(lineCount: lineCount))
    }
}

struct LabelExtractor: UIViewRepresentable {
    @Binding var label: UILabel?

    func makeUIView(context: Context) -> UILabel {
        let label = UILabel()
        DispatchQueue.main.async { self.label = label }
        return label
    }

    func updateUIView(_ uiView: UILabel, context: Context) {}
}


struct TextLineCounter: UIViewRepresentable {
    @Binding var lineCount: Int

    func makeUIView(context: Context) -> UITextView {
        let tv = UITextView()
        tv.isScrollEnabled = false
        tv.isEditable = false
        tv.isSelectable = false
        tv.textContainerInset = .zero
        tv.textContainer.lineFragmentPadding = 0
        tv.backgroundColor = .clear
        return tv
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        guard let label = context.coordinator.label else { return }
        uiView.attributedText = label.attributedText
        
        DispatchQueue.main.async {
            let number = Int(uiView.contentSize.height / uiView.font!.lineHeight)
            if self.lineCount != number {
                self.lineCount = number
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        var label: UILabel?
    }
}
