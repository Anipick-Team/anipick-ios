//
//  CastResponse.swift
//  AniPick
//
//  Created by cho on 9/7/25.
//

import Foundation

struct CastResponse: Codable {
    let code: Int
    let value: String
    let result: [CastPair]
}

struct CastPair: Codable, Hashable {
    let character: AnimeCharacter?
    let voiceActor: VoiceActor?
    let role: String?
}

struct AnimeCharacter: Codable, Hashable {
    let id: Int
    let name: String
    let imageUrl: String?
}

struct VoiceActor: Codable, Hashable {
    let id: Int
    let name: String
    let imageUrl: String?
}
