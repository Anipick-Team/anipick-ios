//
//  AppState.swift
//  AniPick
//
//  Created by cho on 10/7/25.
//

import SwiftUI

final class AppState: ObservableObject {
    @Published var pendingExploreFilter: ExploreFilter?

    func pushExplore(year: String?, season: String?) {
        DLog("explore push push - \(year) - \(season)")
        pendingExploreFilter = .init(year: year, season: season)
    }

    func consumeExploreFilter() -> ExploreFilter? {
        defer { pendingExploreFilter = nil }
        return pendingExploreFilter
    }
}

struct ExploreFilter: Equatable {
    var year: String?
    var season: String?
}
