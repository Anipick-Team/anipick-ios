//
//  DummyHomeSearch.swift
//  AniPick
//
//  Created by cho on 7/16/25.
//

import Foundation

func makeDummyHomeSearchResponse() -> HomeSearchResponse? {
    let jsonString = """
    {
      "code": 200,
      "success": true,
      "result": {
        "count": 3,
        "animeCount": 2,
        "studioCount": 4
        "nextPage": 2,
        "personCount": 1,
        "cursor": {
          "lastId": 123
        },
        "animes": [
          {
            "animeId": 1,
            "title": "진격의 거인",
            "coverImageUrl": "https://example.com/image1.jpg",
            "clickLog": "click_001",
            "impressionLogs": "imp_001"
          },
          {
            "animeId": 2,
            "title": "귀멸의 칼날",
            "coverImageUrl": "https://example.com/image2.jpg",
            "clickLog": "click_002",
            "impressionLogs": null
          }
        ],
        "persons": [
          {
            "personId": 1,
            "name": "카지 유우키",
            "profileImage": "https://example.com/profile1.jpg"
          }
        ],
        "studios": [
          {
            "studioId": 1,
            "name": "WIT STUDIO"
          },
          {
            "studioId": 2,
            "name": "유포테이블"
          }
        ]
      }
    }
    """
    
    guard let data = jsonString.data(using: .utf8) else {
        print("❌ 문자열 → 데이터 변환 실패")
        return nil
    }

    do {
        let decoded = try JSONDecoder().decode(HomeSearchResponse.self, from: data)
        return decoded
    } catch {
        print("❌ JSON 디코딩 실패: \(error)")
        return nil
    }
}
