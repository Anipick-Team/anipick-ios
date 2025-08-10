//
//  ProfileImageResponse.swift
//  AniPick
//
//  Created by cho on 8/10/25.
//

import Foundation

struct ProfileImageResponse: Codable {
    let code: Int
    let value: String
    let result: ProfileImageID
}

struct ProfileImageID: Codable {
    let imageId: Int
}
