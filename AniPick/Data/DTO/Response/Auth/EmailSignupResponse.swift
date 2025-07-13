//
//  EmailSignupResponse.swift
//  AniPick
//
//  Created by cho on 6/8/25.
//

struct EmailSignupResponse: Decodable {
    let code: Int
    let value: String
    let result: Tokens
}
