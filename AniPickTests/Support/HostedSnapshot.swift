//
//  HostedSnapshot.swift
//  AniPickTests
//
//  화면을 창에 올려 UIKit으로 그린 PNG. ImageRenderer는 ScrollView 내용과 UIKit 뷰(UITextView 등)를
//  그리지 않는다 — 설정 메인(ScrollView)과 리뷰 작성(UITextView) 비교에 쓴다.
//

import SwiftUI
import Testing
import UIKit

@MainActor
func hostedSnapshot(_ view: some View, size: CGSize = CGSize(width: 393, height: 852)) throws -> Data {
    let bounds = CGRect(origin: .zero, size: size)
    let controller = UIHostingController(rootView: view)
    let window = UIWindow(frame: bounds)
    window.rootViewController = controller
    window.makeKeyAndVisible()
    defer { window.isHidden = true }
    controller.view.layoutIfNeeded()

    let format = UIGraphicsImageRendererFormat()
    format.scale = 2
    let image = UIGraphicsImageRenderer(bounds: bounds, format: format).image { _ in
        controller.view.drawHierarchy(in: bounds, afterScreenUpdates: true)
    }
    return try #require(image.pngData())
}
