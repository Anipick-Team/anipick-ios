//
//  UIApplication+Extension.swift
//  AniPick
//
//  Created by cho on 9/28/25.
//
import SwiftUI

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder),
                   to: nil, from: nil, for: nil)
    }
}
