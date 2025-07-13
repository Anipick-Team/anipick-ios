//
//  DLog.swift
//  AniPick
//
//  Created by cho on 5/25/25.
//
import SwiftUI

func DLog(
    _ message: Any,
    file: String = #file,
    function: String = #function,
    line: Int = #line
) {
    #if DEBUG
    let fileName = (file as NSString).lastPathComponent
    print("[\(fileName):\(line)] \(function) ➜ \(message)")
    #endif
}

