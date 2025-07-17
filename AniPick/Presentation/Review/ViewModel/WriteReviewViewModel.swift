//
//  WriteReviewViewModel.swift
//  AniPick
//
//  Created by cho on 7/15/25.
//

import SwiftUI

final class WriteReviewViewModel: ObservableObject {
    
    private let navigationManager: NavigationManager
    
    init(navigationManager: NavigationManager) {
        self.navigationManager = navigationManager
    }
    
}
