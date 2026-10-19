//
//  EditEmailViewModel.swift
//  AniPick
//
//  Created by cho on 6/29/25.
//

import SwiftUI
import Alamofire
import Utils

@MainActor
final class EditEmailViewModel: ObservableObject {
    
    private let navigationManager: NavigationManager
    
    @Published var newEmailString: String = ""
    @Published var isShowErrorMessage: Bool = false
    @Published var errorMessage: String = ""
    @Published var passwordString: String = ""
    
    @Published var isInvalidPassword: Bool = false
    @Published var isInvalidEmail: Bool = false
    @Published var isShowEditEmailPopup: Bool = false
    private let session = NetworkSession.authenticated
    
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

    func performLogout() {
        AF.request(LogoutAPI.logout)
            .cURLDescription { description in
                DLog("\(description)")
            }
            .responseDecodable(of: BaseResponse.self) { [weak self] response in
                // 화면이 사라졌으면 아무것도 하지 않는다 (현재 동작 유지)
                guard self != nil else { return }
                switch response.result {
                case .success(let value):
                    DLog("logout success - \(value)")
                case .failure(let error):
                    DLog("logout error - \(error)")
                }
                UserDefaultsManager.shared.logoutAllClearInfo()
                DLog("🔐 [Login] 이메일 변경 후 로그아웃")
                Task {
                    await AppSession.shared.signOut(.userLogout)
                }
            }
    }
    
    func checkEmail() {
        self.isInvalidPassword = false
        session.request(SettingAPI.editEmail(email: self.newEmailString, password: self.passwordString))
            .cURLDescription { description in
                DLog("\(description)")
            }
            .responseDecodable(of: BaseResponse.self) { [weak self] response in
                guard let self else { return }
                switch response.result {
                case .success(let value):
                    DLog("✅ 성공: \(value)")
                    // TODO: code에 따라서 잘못된 거 확인해야함
                        switch value.code {
                        case 200 :
                            UserDefaultsManager.shared.setEmail(self.newEmailString)
                            self.isShowEditEmailPopup = true
                            
                        case 102:
                            self.isShowErrorMessage = true
                            self.errorMessage = "이메일을 입력해주세요."
                        case 103:
                            self.isShowErrorMessage = true
                            self.errorMessage = "올바른 이메일 형식이 아닙니다."
                        case 106:
                            self.isInvalidPassword = true
                        case 109:
                            self.isShowErrorMessage = true
                            self.errorMessage = "이미 존재하는 이메일입니다."
                        default:
                            self.isShowErrorMessage = true
                            self.errorMessage = "에러 발생"

                    }
                    
                case .failure(let error):
                    DLog("❌ 실패: \(error)")
                }
                
            }
    }
}
