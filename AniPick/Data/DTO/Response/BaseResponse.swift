//
//  BaseResponse.swift
//  AniPick
//
//  Created by cho on 6/4/25.
//

struct BaseResponse: Decodable {
    let code: Int
    let value: String
    /// 서버 비즈니스 오류 시 사용자 노출용 문구 (HTTP 200 + code != 200으로 내려옴)
    let errorValue: String?
}
