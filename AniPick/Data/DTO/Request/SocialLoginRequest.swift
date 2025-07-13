//
//  SocialLoginRequest.swift
//  AniPick
//
//  Created by cho on 6/8/25.
//

struct SocialLoginRequest: Encodable {
    let platform: String
    let code: String
}
