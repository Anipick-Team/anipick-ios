//
//  InquiryView.swift
//  AniPick
//
//  Created by cho on 7/20/25.
//

import SwiftUI
import WebKit

struct InquiryView: View {
    var body: some View {
        WebView(url: URL(string: "https://anipick.p-e.kr/terms.html")!)
            .navigationTitle("이용약관")
            .navigationBarTitleDisplayMode(.inline)
    }
}

struct WebView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        WKWebView()
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        uiView.load(request)
    }
}
