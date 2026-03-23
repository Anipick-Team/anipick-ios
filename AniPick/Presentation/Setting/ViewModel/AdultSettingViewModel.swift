//
//  AdultSettingViewModel.swift
//  AniPick
//

import SwiftUI

final class AdultSettingViewModel: ObservableObject {
    @Published var isAdultVerified: Bool = false
    @Published var isAdultContentEnabled: Bool = false

    private let navigationManager: NavigationManager

    init(navigationManager: NavigationManager) {
        self.navigationManager = navigationManager
        self.loadSettings()
    }

    private func loadSettings() {
        self.isAdultVerified = UserDefaults.standard.bool(forKey: "isAdultVerified")
        self.isAdultContentEnabled = UserDefaults.standard.bool(forKey: "isAdultContentEnabled")
    }

    func tappedSave() {
        UserDefaults.standard.set(isAdultContentEnabled, forKey: "isAdultContentEnabled")
        self.navigationManager.pop()
    }

    func tappedVerification() {
        self.navigationManager.push(route: .adultCheck)
    }

    func moveToBack() {
        self.navigationManager.pop()
    }
}
