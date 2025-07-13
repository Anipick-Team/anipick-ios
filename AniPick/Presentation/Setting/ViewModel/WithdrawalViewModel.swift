//
//  WithdrawalViewModel.swift
//  AniPick
//
//  Created by cho on 6/29/25.
//

import SwiftUI

final class WithdrawalViewModel: ObservableObject {
    private let navigationManager: NavigationManager
    
    init(navigationManager: NavigationManager) {
        self.navigationManager = navigationManager
    }
    
    @Published var isEnableWithdrawalButton: Bool = false
    
    
}
