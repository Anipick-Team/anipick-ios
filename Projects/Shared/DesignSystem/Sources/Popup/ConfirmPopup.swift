import SwiftUI

/// 제목·설명·버튼 1~2개로 된 확인 팝업. `.popup(isPresented:)`와 함께 쓴다.
///
/// - `.standard`: 레거시 `SNSSignupPopupView`·`EditEmailPopupView`와 같은 모양
/// - `.compact`: 레거시 `LogoutPopupView`와 같은 모양 (여백 20, 최대 너비 300, 제목 아래 8)
///
/// 두 모양 중 무엇이 표준인지는 Figma 대조 후 정한다 (이관 2-1b).
///
/// ```swift
/// .popup(isPresented: store.state.isLogoutConfirmPresented) {
///     ConfirmPopup(title: "로그아웃", message: "로그아웃 하시겠습니까?", confirmTitle: "로그아웃") {
///         store.send(.logoutCancelled)
///     } onConfirm: {
///         store.send(.logoutConfirmed)
///     }
/// }
/// ```
public struct ConfirmPopup: View {
    public enum Style: Sendable {
        case standard
        case compact
    }

    private let style: Style
    private let title: String
    private let message: String
    private let cancelTitle: String?
    private let confirmTitle: String
    private let onCancel: () -> Void
    private let onConfirm: () -> Void

    /// - Parameter cancelTitle: `nil`이면 확인 버튼 하나만 둔다
    public init(
        style: Style = .standard,
        title: String,
        message: String,
        cancelTitle: String? = "취소",
        confirmTitle: String,
        onCancel: @escaping () -> Void = {},
        onConfirm: @escaping () -> Void
    ) {
        self.style = style
        self.title = title
        self.message = message
        self.cancelTitle = cancelTitle
        self.confirmTitle = confirmTitle
        self.onCancel = onCancel
        self.onConfirm = onConfirm
    }

    public var body: some View {
        switch style {
        case .standard:
            content
                .padding(.vertical, 20)
                .padding(20)
                .background(Color.white)
                .cornerRadius(16)
                .padding(.horizontal, 20)
        case .compact:
            content
                .padding(20)
                .background(Color.white)
                .cornerRadius(16)
                .frame(maxWidth: 300)
        }
    }

    private var content: some View {
        return VStack(spacing: 0) {
            Text(title)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.anipickBlack)
                .padding(.bottom, style == .compact ? 8 : 12)

            Text(message)
                .font(.system(size: 14))
                .foregroundColor(.settingSubTitle)

            Spacer().frame(height: 37)

            HStack {
                if let cancelTitle {
                    Button {
                        onCancel()
                    } label: {
                        Text(cancelTitle)
                            .font(.system(size: 16))
                            .foregroundColor(.textGray)
                            .frame(maxWidth: .infinity)
                    }

                    Divider()
                }

                Button {
                    onConfirm()
                } label: {
                    Text(confirmTitle)
                        .font(.system(size: 16))
                        .foregroundColor(.anipickPrimary)
                        .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 22)
        }
    }
}

extension View {
    /// 화면 위에 어두운 배경과 함께 팝업을 띄운다. 표시 여부는 State가 정한다 (MVI B3).
    public func popup<Popup: View>(
        isPresented: Bool,
        @ViewBuilder content: () -> Popup
    ) -> some View {
        return overlay {
            if isPresented {
                ZStack {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                    content()
                }
            }
        }
    }
}

#Preview("버튼 2개 · 1개") {
    VStack {
        ConfirmPopup(title: "로그아웃", message: "로그아웃 하시겠습니까?", confirmTitle: "로그아웃") {}
        ConfirmPopup(
            title: "이메일 변경이 완료되었어요.",
            message: "변경된 이메일로 다시 로그인해 주세요.",
            cancelTitle: nil,
            confirmTitle: "확인"
        ) {}
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.black.opacity(0.5))
}
