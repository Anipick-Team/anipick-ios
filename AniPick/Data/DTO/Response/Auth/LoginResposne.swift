//
//  LoginResposne.swift
//  AniPick
//
//  Created by cho on 6/4/25.
//

struct LoginResponse: Decodable {
    let code: Int
    let value: String
    let result: LoginResult?
}

struct LoginResult: Decodable {
    // TODO: 확인 필요 - reviewCompletedYn이 Bool 값으로 처리하면 되는건지
    let reviewCompletedYn: Bool?
    let userId: Int?
    let nickname: String?
    let token: Token?
}

struct Token: Decodable {
    let accessToken: String
    let refreshToken: String
}
