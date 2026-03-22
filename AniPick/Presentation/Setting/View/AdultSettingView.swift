//
//  AdultSettingView.swift
//  AniPick
//

import SwiftUI

struct AdultSettingView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject var viewModel: AdultSettingViewModel

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 20)

            NavigationBackButtonView(title: "19세 작품") {
                dismiss()
            }

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    sectionDivider()

                    // MARK: - 성인 인증 Row
                    Button {
                        viewModel.tappedVerification()
                    } label: {
                        HStack {
                            Text("성인 인증")
                                .customFontStyle(size: 16, color: .anipickBlack)
                            Spacer()
                            Text(viewModel.isAdultVerified ? "완료" : "미완료")
                                .customFontStyle(
                                    size: 14,
                                    color: viewModel.isAdultVerified ? .anipickPrimary : .gray6
                                )
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                                .font(.system(size: 12))
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 18)
                    }

                    rowDivider()

                    // MARK: - 19세 작품 Toggle Row
                    HStack {
                        Text("19세 작품")
                            .customFontStyle(size: 16, color: .anipickBlack)
                        Spacer()
                        Toggle("", isOn: $viewModel.isAdultContentEnabled)
                            .labelsHidden()
                            .tint(.anipickPrimary)
                            .disabled(!viewModel.isAdultVerified)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)

                    sectionDivider()

                    // MARK: - 안내 문구
                    VStack(alignment: .leading, spacing: 8) {
                        Text("1년에 한번, 확인해주세요!")
                            .customFontStyle(size: 14, color: .anipickBlack, weight: .bold)

                        Text("청소년보호법과 여성가족부의 정책에 따라 연1회 주기로 재인증을\n진행해야 합니다.\n확인 결과는 1년간 애니픽 서비스에 적용됩니다.")
                            .customFontStyle(size: 13, color: .gray6)
                            .lineSpacing(4)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }

            Spacer()

            // MARK: - 저장 버튼
            FullWidthButton(isEnable: .constant(true), buttonText: "저장") {
                viewModel.tappedSave()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
        }
        .background(Color.white)
        .navigationBarBackButtonHidden()
    }

    @ViewBuilder
    private func sectionDivider() -> some View {
        Rectangle()
            .foregroundColor(.gray7)
            .frame(height: 12)
            .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func rowDivider() -> some View {
        Rectangle()
            .foregroundColor(.gray7)
            .frame(height: 1)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)
    }
}

#Preview {
    AppDIContainer.makeAdultSettingView()
}
