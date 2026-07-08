//
//  ResearchViewModel.swift
//  AniPick
//
//  Created by cho on 7/15/25.
//

import SwiftUI

@MainActor
final class ResearchViewModel: ObservableObject {
    
    private let navigationManager: NavigationManager
    
    init(navigationManager: NavigationManager) {
        self.navigationManager = navigationManager
    }
    
}
