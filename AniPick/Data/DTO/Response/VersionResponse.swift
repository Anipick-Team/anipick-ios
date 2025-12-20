//
//  VersionResponse.swift
//  AniPick
//
//  Created by cho on 12/20/25.
//

import Foundation

struct VersionResponse: Decodable {
    let code: Int
    let value: String
    let result: VersionResult
}

struct VersionResult: Decodable {
    let isLatestVersion: Bool?
    let isRequiredUpdate: Bool?
    let type: String?
    let title: String?
    let content: String?
    let url: String?
}

