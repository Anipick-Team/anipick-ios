import DesignSystem
import MVICore
import SwiftUI

/// 레거시 `SettingView`와 같은 배치
struct SettingView: View {
    @State private var store: Store<SettingReducer>

    init(state: SettingReducer.State, reducer: SettingReducer) {
        _store = State(initialValue: Store(initialState: state, reducer: reducer))
    }

    private struct RowItem: Hashable {
        let row: SettingReducer.Row
        var titleColor: Color?
        var subtitle: String?
        var subtitleColor: Color?
        var showsChevron: Bool
    }

    var body: some View {
        ZStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer().frame(height: 20)

                    BackNavigationBar(title: "설정") {
                        store.send(.backTapped)
                    }

                    section(title: "계정", items: accountRows)
                    section(title: "앱 설정", items: appRows)
                    section(
                        title: "기타",
                        items: [
                            RowItem(row: .logout, titleColor: .textRed, showsChevron: false),
                            RowItem(row: .deleteAccount, titleColor: .textRed, showsChevron: false),
                        ]
                    )

                    Spacer().frame(height: 50)
                }
            }
        }
        .background(Color.white)
        .onAppear {
            store.send(.appeared)
        }
        .navigationBarBackButtonHidden()
        .popup(isPresented: store.state.isLogoutPopupPresented) {
            ConfirmPopup(
                style: .compact,
                title: "로그아웃",
                message: "로그아웃 하시겠습니까?",
                confirmTitle: "로그아웃"
            ) {
                store.send(.logoutCancelled)
            } onConfirm: {
                store.send(.logoutConfirmed)
            }
        }
    }

    private var accountRows: [RowItem] {
        let state = store.state
        return [
            RowItem(row: .editNickname, subtitle: state.nickname, showsChevron: true),
            RowItem(row: .editEmail, subtitle: state.email, showsChevron: !state.isSNSAccount),
            RowItem(
                row: .editPassword,
                subtitle: state.isSNSAccount ? "sns 간편가입된 계정입니다." : "",
                subtitleColor: .gray6,
                showsChevron: !state.isSNSAccount
            ),
            RowItem(
                row: .linkedSNS,
                titleColor: .anipickPrimary,
                subtitle: state.snsName,
                subtitleColor: .anipickPrimary,
                showsChevron: false
            ),
        ]
    }

    private var appRows: [RowItem] {
        return [
            RowItem(row: .appVersion, subtitle: store.state.appVersion, showsChevron: false),
            RowItem(row: .inquiry, showsChevron: true),
            RowItem(row: .termsOfService, showsChevron: true),
            RowItem(row: .privacyPolicy, showsChevron: true),
            RowItem(row: .notice, showsChevron: true),
        ]
    }

    private func section(title: String, items: [RowItem]) -> some View {
        return VStack(alignment: .leading, spacing: 0) {
            Rectangle()
                .foregroundColor(.gray7)
                .frame(height: 12)
                .frame(maxWidth: .infinity)
                .background(.gray5)
                .padding(.horizontal, -20)

            Spacer().frame(height: 36)

            Text(title)
                .textStyle(size: 20, color: .anipickBlack, weight: .bold)
                .padding(.bottom, 24)

            ForEach(items, id: \.self) { item in
                row(item)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 32)
    }

    private func row(_ item: RowItem) -> some View {
        return Button {
            store.send(.rowTapped(item.row))
        } label: {
            HStack {
                Text(item.row.rawValue)
                    .textStyle(size: 16, color: item.titleColor ?? .anipickBlack)
                Spacer()
                if let subtitle = item.subtitle {
                    Text(subtitle)
                        .foregroundColor(item.subtitleColor ?? .settingViewText)
                }
                if item.showsChevron {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                        .font(.system(size: 12))
                }
            }
            .font(.system(size: 14))
            .padding(.vertical, 12)
        }
    }
}
