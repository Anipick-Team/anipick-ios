//
//  EditNicknameViewModel.swift
//  AniPick
//
//  Created by cho on 6/29/25.
//

import SwiftUI
import Alamofire

@MainActor
final class EditNicknameViewModel: ObservableObject {
    private let navigationManager: NavigationManager
    
    init(navigationManager: NavigationManager) {
        self.navigationManager = navigationManager
    }
    @Published var newNickname: String = ""
    @Published var isShowErrorMessage: Bool = false
    @Published var errorMessage: String = ""
    
    private let session = NetworkSession.authenticated
    
    func checkDuplicateNickname() {
        // TODO: 닉네임 중복 확인 Api 통신
        
        self.isShowErrorMessage = true
    }
    
    func editNickName() {
        session.request(SettingAPI.editNickname(nickname: self.newNickname))
            .cURLDescription { description in
                DLog("\(description)")
            }
            .responseDecodable(of: BaseResponse.self) { [weak self] response in
                guard let self else { return }
                switch response.result {
                case .success(let value):
                    DLog("edit nickname success - \(value)")
                    if value.code == 200 {
                        DLog("닉네임 변경 성공!")
                        UserDefaultsManager.shared.setNickname(self.newNickname)
                        self.navigationManager.pop()
                        self.isShowErrorMessage = false
                        self.errorMessage = ""
                    } else if value.code == 117 {
                        DLog("닉네임 중복")
                        self.isShowErrorMessage = true
                        self.errorMessage = "이미 사용 중인 닉네임입니다."
                    } else if value.code == 116 {
                        DLog("닉네임 형식 잘못됨")
                        self.isShowErrorMessage = true
                        self.errorMessage = "1~20자의 한글, 영문 대/소문자, 숫자, 특수문자를 조합하여 입력해 주세요."
                    } else if value.code == 118 {
                        DLog("닉네임 미입력")
                        self.isShowErrorMessage = true
                        self.errorMessage = "닉네임을 입력해 주세요."
                    }
                case .failure(let error):
                    DLog("edit nickname error - \(error)")
                }
            }
    }
    
    func pop() {
        self.navigationManager.pop()
    }
}
