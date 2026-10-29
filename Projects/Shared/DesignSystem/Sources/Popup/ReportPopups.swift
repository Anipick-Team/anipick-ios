import SwiftUI

/// 리뷰 ⋮ 버튼의 신고·차단 메뉴 (레거시 `ReportBlockMenuPopup`)
public struct ReportBlockMenu: View {
    private let reportAction: () -> Void
    private let blockAction: () -> Void

    public init(reportAction: @escaping () -> Void, blockAction: @escaping () -> Void) {
        self.reportAction = reportAction
        self.blockAction = blockAction
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(spacing: 0) {
                Button {
                    reportAction()
                } label: {
                    Text("신고")
                        .font(.system(size: 14))
                        .foregroundStyle(.anipickBlack)
                        .padding(15)
                }

                Rectangle()
                    .padding(.horizontal, 15)
                    .foregroundStyle(.gray5)
                    .frame(height: 1)

                Button {
                    blockAction()
                } label: {
                    Text("차단")
                        .font(.system(size: 14))
                        .foregroundStyle(.anipickBlack)
                        .padding(15)
                }
            }
            .frame(width: 72)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .border(.gray5)
                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
            )
            .cornerRadius(8)
            .padding(.vertical, 13)
            .padding(.horizontal, 16)
            .transition(.opacity.combined(with: .move(edge: .top)))
            .zIndex(1)
        }
    }
}

/// 신고 유형 (레거시 `ReportReason`). 서버에는 문구를 그대로 보낸다
public enum ReportReason: String, CaseIterable, Identifiable, Sendable {
    case profanity = "욕설/비하/혐오 표현"
    case personalInformation = "개인정보 노출"
    case spam = "도배/스팸/광고성 내용"
    case harmfulContent = "불법/유해/부적절한 내용"
    case policyViolation = "기타 운영정책 위반"

    public var id: String {
        return rawValue
    }
}

/// 리뷰 신고 창 (레거시 `ReportReviewWithReasonPopupView`). 유형을 고르지 않고 신고하면 안내만 띄운다
public struct ReportReasonPopup: View {
    private let cancelAction: () -> Void
    private let okAction: (String) -> Void
    @State private var selectedReason: ReportReason?
    @State private var isShowingReasonList = false
    @State private var showsValidationMessage = false

    public init(cancelAction: @escaping () -> Void, okAction: @escaping (String) -> Void) {
        self.cancelAction = cancelAction
        self.okAction = okAction
    }

    public var body: some View {
        ZStack {
            Color.black.opacity(0.72)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Text("신고")
                    .textStyle(size: 28, color: .anipickBlack, weight: .bold)
                    .padding(.top, 55)

                Text("신고 유형 선택")
                    .textStyle(size: 22, color: .anipickBlack)
                    .padding(.top, 46)
                    .padding(.bottom, 14)

                reasonSelector

                if showsValidationMessage {
                    Text("신고 유형을 선택해 주세요.")
                        .textStyle(size: 16, color: .anipickPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 10)
                }

                Spacer(minLength: 28)

                actionButtons
                    .padding(.bottom, 42)
            }
            .frame(maxWidth: 724)
            .padding(.horizontal, 80)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 40)
        }
    }

    private var reasonSelector: some View {
        return VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.15)) {
                    isShowingReasonList.toggle()
                }
            } label: {
                HStack(spacing: 0) {
                    Text(selectedReason?.rawValue ?? "신고 유형 선택")
                        .textStyle(size: 20, color: selectedReason == nil ? .gray8 : .anipickBlack)

                    Spacer()

                    Image(systemName: isShowingReasonList ? "chevron.up" : "chevron.down")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(.anipickBlack)
                }
                .padding(.horizontal, 32)
                .frame(height: 92)
                .background(Color.gray7)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)

            if isShowingReasonList {
                VStack(spacing: 0) {
                    ForEach(ReportReason.allCases) { reason in
                        Button {
                            selectedReason = reason
                            showsValidationMessage = false
                            withAnimation(.easeInOut(duration: 0.15)) {
                                isShowingReasonList = false
                            }
                        } label: {
                            Text(reason.rawValue)
                                .textStyle(size: 20, color: .anipickBlack)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .frame(height: 70)
                                .padding(.horizontal, 32)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .background(Color.gray7)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private var actionButtons: some View {
        return HStack(spacing: 0) {
            Button {
                cancelAction()
            } label: {
                Text("닫기")
                    .textStyle(size: 20, color: .gray6)
                    .frame(maxWidth: .infinity)
            }

            Rectangle()
                .fill(Color.gray6)
                .frame(width: 1, height: 28)

            Button {
                guard let selectedReason else {
                    showsValidationMessage = true
                    return
                }
                okAction(selectedReason.rawValue)
            } label: {
                Text("신고하기")
                    .textStyle(size: 20, color: .anipickPrimary)
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 28)
    }
}

/// 사용자 차단 확인 창 (레거시 `BlockUserPopupView`)
public struct BlockUserPopup: View {
    private let cancelAction: () -> Void
    private let okAction: () -> Void

    public init(cancelAction: @escaping () -> Void, okAction: @escaping () -> Void) {
        self.cancelAction = cancelAction
        self.okAction = okAction
    }

    public var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Text("사용자를 차단하시겠습니까?")
                    .textStyle(size: 20, color: .anipickBlack, weight: .bold)
                    .padding(.bottom, 8)

                // "콘첸츠"는 레거시 문구 그대로 (오타)
                Text("차단한 사용자의 리뷰, 커뮤니티 게시글 및 댓글 등 모든 콘첸츠가 노출되지 않게 됩니다.")
                    .textStyle(size: 14, color: .settingSubTitle)
                    .multilineTextAlignment(.center)

                Spacer().frame(height: 40)

                HStack {
                    Button {
                        cancelAction()
                    } label: {
                        Text("취소")
                            .textStyle(size: 16, color: .gray6)
                            .frame(maxWidth: .infinity)
                    }

                    Divider()

                    Button {
                        okAction()
                    } label: {
                        Text("확인")
                            .textStyle(size: 16, color: .anipickPrimary)
                            .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 22)
            }
            .padding(20)
            .background(Color.white)
            .cornerRadius(16)
            .padding(.horizontal, 20)
        }
    }
}
