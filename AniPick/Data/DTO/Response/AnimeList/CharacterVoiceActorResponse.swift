import Foundation

// MARK: - Top-Level Response
struct CharacterVoiceActorResponse: Codable {
    let code: Int
    let value: String
    let result: [CharacterVoicePair]
}

// MARK: - Character + VoiceActor Pair
struct CharacterVoicePair: Codable, Identifiable {
    let character: CharacterInfo
    let voiceActor: VoiceActorInfo

    // For convenience (e.g., ForEach)
    var id: String {
        "\(character.id)-\(voiceActor.id)"
    }
}

// MARK: - Character Info
struct CharacterInfo: Codable, Identifiable {
    let id: Int
    let name: String
    let imageUrl: String
}

// MARK: - Voice Actor Info
struct VoiceActorInfo: Codable, Identifiable {
    let id: Int
    let name: String
    let im
