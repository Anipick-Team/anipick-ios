//
//  CharacterVoiceActorResponse.swift
//  AniPick
//
//  Created by cho on 7/13/25.
//


import Foundation

struct CharacterVoiceActorResponse: Decodable {
    let code: Int
    let value: String
    let result: [CharacterVoicePair]
}

struct CharacterVoicePair: Decodable, Identifiable {
    let id = UUID()
    let character: CharacterInfo
    let voiceActor: VoiceActorInfo
}

struct CharacterInfo: Decodable, Identifiable {
    let id: Int
    let name: String
    let imageUrl: String
}

struct VoiceActorInfo: Decodable, Identifiable {
    let id: Int
    let name: String
    let imageUrl: String
}
