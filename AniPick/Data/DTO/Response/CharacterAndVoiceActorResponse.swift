//
//  CharacterAndVoiceActorResponse.swift
//  AniPick
//
//  Created by cho on 9/7/25.
//

import Foundation

struct CharacterAndVoiceActorResponse: Decodable {
    let code: Int
    let value: String
    let result: CharacterAndVoiceActorPair
}

struct CharacterAndVoiceActorPair: Decodable {
    let cursor: Cursor
    let characters: [CharacterAndVoiceActorInfo]
}

struct CharacterAndVoiceActorInfo: Decodable, Hashable {
    let character: AnimeCharacter?
    let voiceActor: VoiceActor?
    let role: String?
}

