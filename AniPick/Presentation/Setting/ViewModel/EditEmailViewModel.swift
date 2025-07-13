//
//  EditEmailViewModel.swift
//  AniPick
//
//  Created by cho on 6/29/25.
//

import SwiftUI

final class EditEmailViewModel: ObservableObject {
    
    private let navigationManager: NavigationManager
    
    @Published var newEmailString: String = ""
    @Published var isShowErrorMessage: Bool = false
    @Published var errorMessage: String = ""
    
    @Published var isInvalidPassword: Bool = true
    @Published var isInvalidEmail: Bool = true
    
    init(navigationManager: NavigationManager) {
        self.navigationManager = navigationManager
    }

   
    // TODO: 이메일 관련 오류 메시지 전달 필요
    func checkDuplicateEmail() {
        // TODO: API 연결 필요.
        // TODO: 올바른 이메일인지 확인 후, 응답값 보내야함
        self.isShowErrorMessage = false
        self.errorMessage = "올바른 이메일 형식이 아닙니다."
    }
    
    func checkInvalidPassword() {
        // TODO: 비밀번호가 일치하지 않습니다.
    }
}
