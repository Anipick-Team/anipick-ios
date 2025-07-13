//
//  AppState.swift
//  AniPick
//
//  Created by cho on 6/19/25.
//

import SwiftUI

final class AppState: ObservableObject {
    enum AuthState {
        case checking
        case authenticated
        case unauthenticated
    }
    
    @Published var authState: AuthState = .checking
}
