//
//  RefreshResponse.swift
//  AniPick
//
//  Created by cho on 6/8/25.
//

struct RefreshResponse: Decodable {
    let code: Int
    let value: String
    let result: Tokens?
    let errorReason: String?
}

struct Tokens: Decodable {
    let accessToken: String
    let refreshToken: String
}
