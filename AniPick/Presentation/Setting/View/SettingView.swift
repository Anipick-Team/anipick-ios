//
//  SettingView.swift
//  AniPick
//
//  Created by cho on 4/14/25.
//

import SwiftUI

struct SettingView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Spacer().frame(height: 20)
                
                NavigationBackButtonView(title: "설정") {
                    dismiss()
                }
                    
                // MARK: - 계정 Section
                let firstSectionItem = [
                    SettingInfoData(
                        title: "닉네임 변경",
                        titleColor: nil,
                        subtitle: "동당동당",
                        subtitleColor: nil,
                        isShowChevron: true
                    ),
                    SettingInfoData(
                        title: "이메일 변경",
                        titleColor: nil,
                        subtitle: "example@examople.com",
                        subtitleColor: nil,
                        isShowChevron: true
                    ),
                    SettingInfoData(
                        title: "비밀번호 변경",
                        titleColor: nil,
                        subtitle: nil,
                        subtitleColor: nil,
                        isShowChevron: true
                    ),
                    SettingInfoData(
                        title: "연동 SNS",
                        titleColor: .anipickPrimary,
                        subtitle: "카카오톡",
                        subtitleColor: .anipickPrimary,
                        isShowChevron: false
                    )
                ]
                
                section(title: "계정", items: firstSectionItem)
                // MARK: - 앱 설정 Section
                let secondSectionItem = [
                    SettingInfoData(
                        title: "앱 버전",
                        titleColor: nil,
                        subtitle: "1.0",
                        subtitleColor: nil,
                        isShowChevron: false
                    ),
                    SettingInfoData(
                        title: "문의하기",
                        titleColor: nil,
                        subtitle: nil,
                        subtitleColor: nil,
                        isShowChevron: true
                    ),
                    SettingInfoData(
                        title: "서비스 이용약관",
                        titleColor: nil,
                        subtitle: nil,
                        subtitleColor: nil,
                        isShowChevron: true
                    ),
                    SettingInfoData(
                        title: "개인정보 처리방침",
                        titleColor: nil,
                        subtitle: nil,
                        subtitleColor: nil,
                        isShowChevron: true
                    ),
                    SettingInfoData(
                        title: "공지사항",
                        titleColor: nil,
                        subtitle: nil,
                        subtitleColor: nil,
                        isShowChevron: true
                    )
                ]
               
                section(title: "앱 설정", items: secondSectionItem)

                
                let thirdSectionItem: [SettingInfoData] = [
                    SettingInfoData(
                        title: "로그아웃",
                        titleColor: .textRed,
                        subtitle: nil,
                        subtitleColor: nil,
                        isShowChevron: false
                    ),
                    SettingInfoData(
                        title: "회원탈퇴",
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
        HStack {
            Text(detailInfo.title)
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
    
//    @ViewBuilder
//    private func section(
//        categoryTitle: String,
//        subtitle: String,
//                         items: [(String, String?, Bool, Color?)]
//    ) -> some View {
//        
//        VStack(alignment: .leading, spacing: 0) {
//            self.sectionDivder()
//                .padding(.horizontal, -20)
//            
//            Spacer().frame(height: 36)
//            
//            Text(title)
//                .customFontStyle(size: 20, color: .anipickBlack, weight: .bold)
//                .padding(.bottom, 24)
//            
//            ForEach(0..<items.count, id: \.self) { index in
//                let item = items[index]
//                HStack {
//                    Text(item.0)
//                        .customFontStyle(size: 16, color: item.3 ?? .anipickBlack)
//                    Spacer()
//                    if let right = item.1 {
//                        Text(right)
//                            .foregroundColor(item.3 ?? .settingViewText)
//                    }
//                    if !item.2 {
//                        Image(systemName: "chevron.right")
//                            .foregroundColor(.gray)
//                            .font(.system(size: 12))
//                    }
//                }
//                .font(.system(size: 14))
//                .padding(.vertical, 12)
//
//            }
//        }
//        .padding(.horizontal, 20)
//        .padding(.top, 32)
//    }

//    private func section(title: String, items: [(String, String?, Bool)]) -> some View {
//        section(title: title, items: items.map { ($0.0, $0.1, $0.2, nil) })
//    }
    
    @ViewBuilder
    private func sectionDivder() -> some View {
        Rectangle()
            .foregroundColor(.gray7)
            .frame(height: 12)
            .frame(maxWidth: .infinity)
            .background(.gray5)
        
    }
}


struct SettingInfoData: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let titleColor: Color?
    let subtitle: String?
    let subtitleColor: Color?
    let isShowChevron: Bool
}
#Preview {
    SettingView()
}
