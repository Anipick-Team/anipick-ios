//
//  EditPasswordViewModel.swift
//  AniPick
//
//  Created by cho on 6/29/25.
//

import SwiftUI
import Alamofire

final class EditPasswordViewModel: ObservableObject {
    
    private let navigationManager: NavigationManager
    let session = Session(interceptor: TokenInterceptor.shared)
    init(navigationManager: NavigationManager) {
        self.navigationManager = navigationManager
    }
    
    @Published var currentPassword: String = ""
    @Published var newPassword: String = "" {
        didSet {
            isPasswordValid()
        }
    }
    @Published var checkNewPassword: String = "" {
        didSet {
            checkDuplicatePassword()
        }
    }
    
    @Published var isValidatePassword: Bool = false
    
    @Published var isShowCurrentPasswordError: Bool = false
    @Published var currentPasswordErrorMessage: String = ""
    
    @Published var isShowNewPasswordError: Bool = false
    @Published var NewErrorMessage: String = ""
    @Published var checkNewErrorMessage: String = ""
    
    @Published var isShowGreenCheckDoublePW: Bool = false
    
    
    
}

extension EditPasswordViewModel {
    func checkDuplicatePassword() {
        if self.newPassword == self.checkNewPassword {
            self.isShowGreenCheckDoublePW = true
        }
    }
    
    private func isPasswordValid()  {
        
        let stringCount = newPassword.count >= 10
        
        // TODO: 정규식으로 교체
        // hasLetter - 영문자가 하나라도 포함되어 있으면 true
        let hasLetter = newPassword.range(of: "[a-zA-Z]", options: .regularExpression) != nil
        // hasNumber - 숫자가 하나라도 포함되어 있으면 true
        let hasNumber = newPassword.rangeOfCharacter(from: .decimalDigits) != nil
        // hasSpecialtrue - 특수문자가 하나라도 있으면 true
        let specialCharRegex = "[^A-Za-z0-9]"
        let hasSpecialChar = newPassword.range(of: specialCharRegex, options: .regularExpression) != nil
       
        let trueCount = [hasLetter, hasNumber, hasSpecialChar].filter { $0 }.count
        
        self.isValidatePassword = stringCount && trueCount >= 2
        if self.isValidatePassword == false {
            self.NewErrorMessage = "8~16자의 영문 대/소문자, 숫자, 특수문자를 조합하여 입력해 주세요."
        }
    }
    
    func editPassword() {
        session.request(SettingAPI.editPassword(currentPassword: self.currentPassword, newPassword: self.newPassword, confirmNewPassword: self.checkNewPassword))
            .cURLDescription { description in
                DLog("\(description)")
            }
            .responseDecodable(of: BaseResponse.self) { response in
                switch response.result {
                case .success(let value):
                    DLog("edit password - \(value)")
                    self.resetErrorMessage()
                    if value.code == 200 {
                        DLog("비번 변경 성공~~~")
                        self.navigationManager.pop()
                    } else if value.code == 107 {
                        DLog("현재 비밀번호 일치하지 않음")
                        self.currentPasswordErrorMessage = "현재 비밀번호가 일치하지 않습니다. 다시 입력해주세요."
                    } else if value.code == 108 {
                        DLog("비밀번호가 서로 다름!")
                        self.checkNewErrorMessage = "비밀번호가 일치하지 않습니다."
                    }
                case .failure(let error):
                    self.resetErrorMessage()
                    DLog("edit Password error - \(error)")
                }
            }
    }
    
    private func resetErrorMessage() {
        self.currentPasswordErrorMessage = ""
        self.NewErrorMessage = ""
        self.checkNewErrorMessage = ""
    }
}
