//
//  EditEmailViewModel.swift
//  AniPick
//
//  Created by cho on 6/29/25.
//

import SwiftUI
import Alamofire

final class EditEmailViewModel: ObservableObject {
    
    private let navigationManager: NavigationManager
    
    @Published var newEmailString: String = ""
    @Published var isShowErrorMessage: Bool = false
    @Published var errorMessage: String = ""
    @Published var passwordString: String = ""
    
    @Published var isInvalidPassword: Bool = false
    @Published var isInvalidEmail: Bool = false
    let session = Session(interceptor: TokenInterceptor.shared)
    
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
    
    func checkEmail() {
        session.request(SettingAPI.editEmail(email: self.newEmailString, password: self.passwordString))
            .cURLDescription { description in
                DLog("\(description)")
            }
            .responseDecodable(of: BaseResponse.self) { response in
                switch response.result {
                case .success(let value):
                    DLog("✅ 성공: \(value)")
                    UserDefaultsManager.shared.setEmail(self.newEmailString)
                    self.navigationManager.pop()
                case .failure(let error):
                    DLog("❌ 실패: \(error)")
                }
                
            }
    }
}
