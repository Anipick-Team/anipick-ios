//
//  EditNicknameViewModel.swift
//  AniPick
//
//  Created by cho on 6/29/25.
//

import SwiftUI

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
}
