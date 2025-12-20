//
//  NotificationManager.swift
//  AniPick
//
//  Created by cho on 7/23/25.
//

import Foundation

extension Notification.Name {
    static let didSelectSeason = Notification.Name("didSelectSeason")
    static let presentReportPopup = Notification.Name("presentReportPopup")
    static let presentBlockUserPopup = Notification.Name("presentBlockUserPopup")
    static let reloadRatedAnime = Notification.Name("reloadRatedAnime")
}




struct SeasonNotificationManager {
    static func post(season: Int, seasonYear: Int) {
        NotificationCenter.default.post(
            name: .didSelectSeason,
            object: nil,
            userInfo: [
                "season": season,
                "seasonYear": seasonYear
            ]
        )
    }
    
    static func postReportPoup() {
        NotificationCenter.default.post(
            name: .presentReportPopup,
            object: nil
        )
    }
    
    
    static func observe(_ observer: Any, selector: Selector) {
        NotificationCenter.default.addObserver(
            observer,
            selector: selector,
            name: .didSelectSeason,
            object: nil
        )
    }
    
    static func remove(_ observer: Any) {
        NotificationCenter.default.removeObserver(
            observer,
            name: .didSelectSeason,
            object: nil
        )
    }
}


extension SeasonNotificationManager {
    
}
