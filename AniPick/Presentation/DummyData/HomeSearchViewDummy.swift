//
//  HomeSearchViewDummy.swift
//  AniPick
//
//  Created by cho on 7/16/25.
//

import Foundation

func makeDummySearchStudioQueryResponse() -> SearchStudioQueryResponse? {
    let jsonString = """
    {
      "code": 200,
      "success": true,
      "result": {
        "count": 8,
        "animeCount": 11,
        "personCount": 4,
        "cursor": {
          "lastId": 8
        },
        "studios": [
          { "studioId": 1, "name": "유포테이블" },
          { "studioId": 2, "name": "WIT STUDIO" },
          { "studioId": 3, "name": "MAPPA" },
          { "studioId": 4, "name": "A-1 Pictures" },
          { "studioId": 5, "name": "Bones" },
          { "studioId": 6, "name": "Studio Pierrot" },
          { "studioId": 7, "name": "Trigger" },
          { "studioId": 8, "name": "Production I.G" }
        ]
      }
    }
    """

    guard let jsonData = jsonString.data(using: .utf8) else {
        print("❌ JSON 문자열을 데이터로 변환할 수 없음")
        return nil
    }

    do {
        let decoded = try JSONDecoder().decode(SearchStudioQueryResponse.self, from: jsonData)
        return decoded
    } catch {
        print("❌ 디코딩 실패:", error)
        return nil
    }
}
