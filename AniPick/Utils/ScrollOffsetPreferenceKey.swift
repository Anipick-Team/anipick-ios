//
//  ScrollOffsetPreferenceKey.swift
//  AniPick
//
//  Created by cho on 5/25/25.
//
import SwiftUI

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
