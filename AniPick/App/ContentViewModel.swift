//
//  ContentViewModel.swift
//  AniPick
//
//  Created by cho on 7/17/25.
//

import SwiftUI

final class ContentViewModel: ObservableObject {
    private let navigationManager: NavigationManager
    
    init(navigationManager: NavigationManager) {
        self.navigationManager = navigationManager
    }
    
}
