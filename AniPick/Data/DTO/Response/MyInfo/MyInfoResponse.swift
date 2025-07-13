//
//  MyInfoResponse.swift
//  AniPick
//
//  Created by cho on 7/13/25.
//

import Foundation

import Foundation

struct MyInfoResponse: Decodable {
    let code: Int
    let value: String
    let result: UserProfile
}

struct UserProfile: Decodable {
    let nickname: String
    let profileImageUrl: String
    let watchCounts: WatchCounts
    let likedAnimes: [LikedAnime]
    let likedPersons: [LikedPerson]
}

struct WatchCounts: Decodable {
    let watchList: Int
    let watching: Int
    let finished: Int
}

struct LikedAnime: Decodable { // 최대 10개
    let animeId: Int
    let animeLikeId: Int
    let title: String
    let coverImageUrl: String
}

struct LikedPerson: Decodable { //최대 10개
    let personId: Int
    let userLikedVoiceActorId: Int
    let name: String
    let profileImageUrl: String
}

