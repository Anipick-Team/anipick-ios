//
//  CountdownButton.swift
//  AniPick
//
//  Created by cho on 9/14/25.
//

import SwiftUI

struct CountdownButton: View {
    let duration: TimeInterval = 180            // 3분
    var onFinished: (() -> Void)? = nil         // 끝났을 때 콜백(옵션)

    @State private var endDate: Date? = nil
    @State private var isRunning = true
    @State private var remaining: Int = 0

    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        Button(action: startIfNeeded) {
            Text(isRunning ? "전송됨 \(formatted(remaining))" : "재발송하기")
                .customFontStyle(size: 16, color: isRunning ? .validNum : .white)
                .frame(maxWidth: .infinity)
                .frame(width: 120, height: 50)
                .background(isRunning ? .white : .anipickPrimary)
                .cornerRadius(8)
                .padding(.leading, 12)

        }
        .disabled(isRunning)
        .onReceive(ticker) { _ in
            guard isRunning, let end = endDate else { return }
            let seconds = max(0, Int(end.timeIntervalSinceNow.rounded(.down)))
            remaining = seconds
            if seconds == 0 {
                isRunning = false
                endDate = nil
                onFinished?()
            }
        }
        // 앱이 다시 포그라운드로 올 때도 남은 시간 갱신
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            guard isRunning, let end = endDate else { return }
            remaining = max(0, Int(end.timeIntervalSinceNow.rounded(.down)))
        }
    }

    private func startIfNeeded() {
        guard !isRunning else { return }
        endDate = Date().addingTimeInterval(duration)
        remaining = Int(duration)
        isRunning = true
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func formatted(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
}
