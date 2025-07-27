//
//  EditNicknameViewModel.swift
//  AniPick
//
//  Created by cho on 6/29/25.
//

import SwiftUI
import Alamofire

final class EditNicknameViewModel: ObservableObject {
    private let navigationManager: NavigationManager
    
    init(navigationManager: NavigationManager) {
        self.navigationManager = navigationManager
    }
    @Published var newNickname: String = ""
    @Published var isDuplicateNickname: Bool = true
    
    
    
    func checkDuplicateNickname() {
        // TODO: 닉네임 중복 확인 Api 통신
        
        self.isDuplicateNickname = true
    }
    
    func editNickName() {
        AF.request(SettingAPI.editNickname(nickname: self.newNickname))
            .cURLDescription { description in
                DLog("\(description)")
            }
            .responseDecodable(of: BaseResponse.self) { response in
                switch response.result {
                case .success(let value):
                    DLog("edit nickname success - \(value)")
                    UserDefaultsManager.shared.setNickname(self.newNickname)
                case .failure(let error):
                    DLog("edit nickname error - \(error)")
                }
            }
    }
}
