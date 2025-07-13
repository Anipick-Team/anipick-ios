//
//  Encodable+Extension.swift
//  AniPick
//
//  Created by cho on 6/13/25.
//
import SwiftUI

extension Encodable {
    func toDictionary() throws -> [String: Any] {
        let data = try JSONEncoder().encode(self)
        let jsonObject = try JSONSerialization.jsonObject(with: data)
        guard let dictionary = jsonObject as? [String: Any] else {
            throw NSError(domain: "EncodingError", code: -1, userInfo: nil)
        }
        return dictionary
    }
}
