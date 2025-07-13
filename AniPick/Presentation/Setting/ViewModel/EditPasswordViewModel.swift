//
//  EditPasswordViewModel.swift
//  AniPick
//
//  Created by cho on 6/29/25.
//

import SwiftUI

final class EditPasswordViewModel: ObservableObject {
    
    private let navigationManager: NavigationManager
    
    init(navigationManager: NavigationManager) {
        self.navigationManager = navigationManager
    }
    
    @Published var currentPassword: String = "123123"
    @Published var newPassword: String = "111111"
    @Published var isShowCurrentPasswordError: Bool = false
    @Published var currentPasswordErrorMessage: String = "현재 비밀번호가 일치하지 않습니다."
    
    @Published var isShowNewPasswordError: Bool = false
    @Published var NewErrorMessage: String = "현재 비밀번호가 일치하지 않습니다."
    @Published var checkNewErrorMessage: String = "비밀번호가 일치하지 않습니다아ㅏㅇ"
    
    @Published var checkNewPassword: String = "111112"
}
