//
//  SearchTab.swift
//  AniPick
//
//  Created by cho on 7/16/25.
//
import SwiftUI

enum SearchTab: String, CaseIterable, Identifiable {
    var id: String { self.rawValue }
    case animation = "작품"
    case person = "인물"
    case producer = "제작사"
    case initSearch = "인기 작품"
    
    static var visibleTabs: [SearchTab] {
        return allCases.filter { $0 != .initSearch }
    }
}
