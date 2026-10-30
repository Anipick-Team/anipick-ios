import DesignSystem
import MVICore
import SwiftUI

/// 레거시 `EditNicknameView`와 같은 배치
struct EditNicknameView: View {
    @State private var store: Store<EditNicknameReducer>

    init(state: EditNicknameReducer.State, reducer: EditNicknameReducer) {
        _store = State(initialValue: Store(initialState: state, reducer: reducer))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer().frame(height: 20)

            BackNavigationBar(title: "닉네임 변경") {
                store.send(.backTapped)
            }
            .padding(.horizontal, -20)

            Spacer().frame(height: 30)

            sectionDivider()
                .padding(.horizontal, -20)

            Spacer().frame(height: 36)

            Text("기존 닉네임")
                .textStyle(size: 18, color: .anipickBlack, weight: .bold)
                .padding(.bottom, 12)

            Text(store.state.currentNickname)
                .textStyle(size: 16, color: .anipickBlack)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: 20)
                .padding(16)
                .background(Color.gray5)
                .cornerRadius(8)
                .multilineTextAlignment(.leading)

            Spacer().frame(height: 32)

            LabeledTextField(
                title: "새 닉네임",
                placeholder: "새 닉네임 입력",
                text: Binding(
                    get: { store.state.newNickname },
                    set: { store.send(.newNicknameChanged($0)) }
                )
            )
            .padding(.bottom, 12)

            if let errorMessage = store.state.errorMessage {
                Text(errorMessage)
                    .textStyle(size: 14, color: .point, weight: .semibold)
            }

            Spacer()

            Rectangle()
                .frame(maxWidth: .infinity)
                .padding(.horizontal, -40)
                .frame(height: 1)
                .foregroundStyle(Color.gray6)

            Spacer().frame(height: 32)

            PrimaryButton("저장") {
                store.send(.saveTapped)
            }
        }
        .padding(.horizontal, 20)
        .navigationBarBackButtonHidden(true)
        .background(Color.white)
    }

    private func sectionDivider() -> some View {
        return Rectangle()
            .foregroundColor(.gray7)
            .frame(height: 12)
            .frame(maxWidth: .infinity)
            .background(.gray5)
    }
}
