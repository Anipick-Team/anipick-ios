//
//  ReportReviewWithReasonPopupView.swift
//  AniPick
//

import SwiftUI

struct ReportReviewWithReasonPopupView: View {
    let cancelAction: () -> Void
    let okAction: (String) -> Void

    @State private var selectedReason: ReportReason?
    @State private var isShowingReasonList = false
    @State private var showsValidationMessage = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.72)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Text("신고")
                    .customFontStyle(size: 28, color: .anipickBlack, weight: .bold)
                    .padding(.top, 55)

                Text("신고 유형 선택")
                    .customFontStyle(size: 22, color: .anipickBlack)
                    .padding(.top, 46)
                    .padding(.bottom, 14)

                reasonSelector

                if showsValidationMessage {
                    Text("신고 유형을 선택해 주세요.")
                        .customFontStyle(size: 16, color: .anipickPrimary)
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
        VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.15)) {
                    isShowingReasonList.toggle()
                }
            } label: {
                HStack(spacing: 0) {
                    Text(selectedReason?.rawValue ?? "신고 유형 선택")
                        .customFontStyle(
                            size: 20,
                            color: selectedReason == nil ? .gray8 : .anipickBlack
                        )

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
                                .customFontStyle(size: 20, color: .anipickBlack)
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
        HStack(spacing: 0) {
            Button {
                cancelAction()
            } label: {
                Text("닫기")
                    .customFontStyle(size: 20, color: .textGray)
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
                    .customFontStyle(
                        size: 20,
                        color: showsValidationMessage ? .primaryColor : .anipickPrimary
                    )
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 28)
    }
}

enum ReportReason: String, CaseIterable, Identifiable {
    case profanity = "욕설/비하/혐오 표현"
    case personalInformation = "개인정보 노출"
    case spam = "도배/스팸/광고성 내용"
    case harmfulContent = "불법/유해/부적절한 내용"
    case policyViolation = "기타 운영정책 위반"

    var id: String { rawValue }
}

#Preview {
    ReportReviewWithReasonPopupView {
        DLog("cancel")
    } okAction: { reason in
        DLog(reason)
    }
}
