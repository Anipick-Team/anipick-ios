//
//  SettingView.swift
//  AniPick
//
//  Created by cho on 4/14/25.
//

import SwiftUI

struct SettingView: View {
    @Environment(\.dismiss) private var dismiss
    
    @StateObject var viewModel: SettingViewModel
    @State private var isSNS: String = UserDefaultsManager.shared.getSNSAccount()
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 0) {
                    Spacer().frame(height: 20)
                    
                    NavigationBackButtonView(title: "설정") {
                        dismiss()
                    }
                    
                    // MARK: - 계정 Section
                    let firstSectionItem = [
                        SettingInfoData(
                            title: SettingCategory.editNickname,
                            titleColor: nil,
                            subtitle: viewModel.nickname,
                            subtitleColor: nil,
                            isShowChevron: true
                        ),
                        SettingInfoData(
                            title: SettingCategory.editEmail,
                            titleColor: nil,
                            subtitle: viewModel.email,
                            subtitleColor: nil,
                            isShowChevron: self.isSNS.isEmpty
                        ),
                        // TODO: SNS 간편 가입된 계정인지 확인 필요
                        SettingInfoData(
                            title: SettingCategory.editPassword,
                            titleColor: nil,
                            subtitle: viewModel.isSNSAccount ? "sns 간편가입된 계정입니다." : "",
                            subtitleColor: .gray6,
                            isShowChevron: self.isSNS.isEmpty
                        ),
                        SettingInfoData(
                            title: SettingCategory.linkedSNS,
                            titleColor: .anipickPrimary,
                            subtitle: viewModel.isShowSNStitle,
                            subtitleColor: .anipickPrimary,
                            isShowChevron: false
                        )
                    ]
                    
                    section(title: "계정", items: firstSectionItem)
                    // MARK: - 앱 설정 Section
                    let secondSectionItem = [
                        SettingInfoData(
                            title: SettingCategory.appVersion,
                            titleColor: nil,
                            subtitle: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
                            subtitleColor: nil,
                            isShowChevron: false
                        ),
                        SettingInfoData(
                            title: SettingCategory.inquiry,
                            titleColor: nil,
                            subtitle: nil,
                            subtitleColor: nil,
                            isShowChevron: true
                        ),
                        SettingInfoData(
                            title: SettingCategory.termsOfService,
                            titleColor: nil,
                            subtitle: nil,
                            subtitleColor: nil,
                            isShowChevron: true
                        ),
                        SettingInfoData(
                            title: SettingCategory.privacyPolicy,
                            titleColor: nil,
                            subtitle: nil,
                            subtitleColor: nil,
                            isShowChevron: true
                        ),
                        SettingInfoData(
                            title: SettingCategory.notice,
                            titleColor: nil,
                            subtitle: nil,
                            subtitleColor: nil,
                            isShowChevron: true
                        )
                    ]
                    
                    section(title: "앱 설정", items: secondSectionItem)
                    
                    
                    let thirdSectionItem: [SettingInfoData] = [
                        SettingInfoData(
                            title: SettingCategory.logout,
                            titleColor: .textRed,
                            subtitle: nil,
                            subtitleColor: nil,
                            isShowChevron: false
                        ),
                        SettingInfoData(
                            title: SettingCategory.deleteAccount,
                            titleColor: .textRed,
                            subtitle: nil,
                            subtitleColor: nil,
                            isShowChevron: false
                        )
                    ]
                    // MARK: - 기타 Section
                    section(title: "기타", items: thirdSectionItem)
                    
                    Spacer()
                        .frame(height: 50)
                }
            }
            
            if viewModel.isShowLogoutPopup {
                LogoutPopupView {
                    viewModel.isShowLogoutPopup = false
                } okAction: {
                    viewModel.tappedLogout()
                    UserDefaultsManager.shared.logoutAllClearInfo()
                }
            }
            
            if viewModel.isShowSNSPopup {
                SNSSignupPopupView {
                    viewModel.isShowSNSPopup = false
                } okAction: {
                    self.viewModel.moveToBack()
                }

            }
        }
        .background(Color.white)
        .onAppear {
            self.viewModel.resetData()
        }
        .navigationBarBackButtonHidden()
    }
    
    @ViewBuilder
    private func section(title: String, items: [SettingInfoData]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            self.sectionDivder()
                .padding(.horizontal, -20)
            
            Spacer().frame(height: 36)
            
            Text(title)
                .customFontStyle(size: 20, color: .anipickBlack, weight: .bold)
                .padding(.bottom, 24)
            
            ForEach(items, id: \.self) { item in
                detailInfoView(detailInfo: item)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 32)
    }
    
    
    @ViewBuilder
    private func detailInfoView(
        detailInfo: SettingInfoData
    ) -> some View {
        Button {
            self.viewModel.actionBySettingCategory(category: detailInfo.title)
                // self.viewModel.moveToDetailSettingView(route: detailInfo.title.route)
        } label: {
            HStack {
                Text(detailInfo.title.rawValue)
                    .customFontStyle(size: 16, color: detailInfo.titleColor ?? .anipickBlack)
                Spacer()
                if let subtitle = detailInfo.subtitle {
                    Text(subtitle)
                        .foregroundColor(detailInfo.subtitleColor ?? .settingViewText)
                }
                if detailInfo.isShowChevron {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                        .font(.system(size: 12))
                }
            }
            .font(.system(size: 14))
            .padding(.vertical, 12)
        }
    }

    @ViewBuilder
    private func sectionDivder() -> some View {
        Rectangle()
            .foregroundColor(.gray7)
            .frame(height: 12)
            .frame(maxWidth: .infinity)
            .background(.gray5)
        
    }
}

enum SettingCategory: String, CaseIterable {
    // 계정
    case editNickname = "닉네임 변경"
    case editEmail = "이메일 변경"
    case editPassword = "비밀번호 변경"
    case linkedSNS = "연동 SNS"
    
    // 앱 설정
    case appVersion = "앱 버전"
    case inquiry = "문의하기"
    case termsOfService = "서비스 이용약관"
    case privacyPolicy = "개인정보 처리방침"
    case notice = "공지사항"
    
    // 기타
    case logout = "로그아웃"
    case deleteAccount = "회원 탈퇴"
}

extension SettingCategory {
    var route: AppRoute {
        switch self {
        case .editNickname: return .editNickname
        case .editEmail: return .editEmail
        case .editPassword: return .editPassword
        case .linkedSNS: return .linkedSNS
        case .appVersion: return .appVersion
        case .inquiry: return .inquiry
        case .termsOfService: return .termsOfService
        case .privacyPolicy: return .privacyPolicy
        case .notice: return .notice
        case .logout: return .logout
        case .deleteAccount: return .deleteAccount
        }
    }
}

struct SettingInfoData: Identifiable, Hashable {
    let id = UUID()
    let title: SettingCategory
    let titleColor: Color?
    let subtitle: String?
    let subtitleColor: Color?
    let isShowChevron: Bool
}

#Preview {
    AppDIContainer.makeSettingView()
}
