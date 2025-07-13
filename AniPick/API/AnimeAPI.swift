//
//  AnimeAPI.swift
//  AniPick
//
//  Created by cho on 7/13/25.
//
import Foundation
import Alamofire

enum AnimeAPI: URLRequestConvertible {
    // 애니 상세 페이지
    case animeDetailInfo(animeId: Int) //  AnimeDetailResponse
    case animeDetailActorInfo(animeId: Int) // CharacterVoiceActorResponse
    case animeDetailSeriesInfo(animeId: Int) // AnimeSeriesListResponse
    case animeDetailRecommendation(animeId: Int) //AnimeSeriesListResponse
    
    // 리뷰 관련
    case reviewList(animeId: Int, sort: String, isSpoiler: Bool, lastValue: String, lastId: Int, size: Int)
    case registerRating(animeId: Int, rating: Double)
    
    case studioDetailInfo(studioId: Int, lastId: Int, lastValue: Int, size: Int)
    case charactersDetailInfo(animeId: Int, lastId: Int, lastValue: Int, size: Int)
    case voiceActorDetailInfo(personId: Int, lastId: Int, size: Int)
    case recommendationAnime(animeId: Int, lastId: Int, size: Int)
    case writeAndEditReview(animeId: Int, content: String, rating: Double, isSpoiler: Bool)
    case seriesAnimeList(animeId: Int, lastId: Int, size: Int)
    
    var path: String {
        switch self {
        case .animeDetailInfo(let animeId):
            return "api/animes/\(animeId)/detail/info"
        case .animeDetailActorInfo(let animeId):
            return "api/animes/\(animeId)/detail/actor"
        case .animeDetailSeriesInfo(let animeId):
            return "api/animes/\(animeId)/detail/series"
        case .animeDetailRecommendation(let animeId):
            return "api/animes/\(animeId)/detail/recommendation"
            
            
        case let .reviewList(animeId, sort, isSpoiler, lastValue, lastId, size):
            return "api/animes/\(animeId)/reviews?sort={}"
        case let .registerRating(animeId, _):
            return "api/rating/\(animeId)/reviews"
            
            
        case .studioDetailInfo(let studioId, let lastId, let lastValue, let size):
            <#code#>
        case .charactersDetailInfo(let animeId, let lastId, let lastValue, let size):
            <#code#>
        case .voiceActorDetailInfo(let personId, let lastId, let size):
            <#code#>
        case .recommendationAnime(let animeId, let lastId, let size):
            <#code#>
        case .writeAndEditReview(let animeId, let content, let rating, let isSpoiler):
            <#code#>
        case .seriesAnimeList(let animeId, let lastId, let size):
            <#code#>
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .animeDetailInfo:
            return .get
        case .animeDetailActorInfo:
            return .get
        case .animeDetailSeriesInfo:
            return .get
        case .animeDetailRecommendation:
            return .get
            
            
        case .reviewList:
            return .get
        case .registerRating:
            return .post
            
        case .studioDetailInfo(let studioId, let lastId, let lastValue, let size):
            <#code#>
        case .charactersDetailInfo(let animeId, let lastId, let lastValue, let size):
            <#code#>
        case .voiceActorDetailInfo(let personId, let lastId, let size):
            <#code#>
        case .recommendationAnime(let animeId, let lastId, let size):
            <#code#>
        case .writeAndEditReview(let animeId, let content, let rating, let isSpoiler):
            <#code#>
        case .seriesAnimeList(let animeId, let lastId, let size):
            <#code#>
        }

    }
    
    var parameters: Parameters? {
        switch self {
        case .animeDetailInfo:
            return nil
        case .animeDetailActorInfo:
            return nil
        case .animeDetailSeriesInfo:
            return nil
        case .animeDetailRecommendation:
            return nil
            
        case let .reviewList(_, sort, isSpoiler, lastValue, lastId, size):
            return [
                "sort": sort,        //정렬 기준 (latest, likes, ratingDesc, ratingAsc)
                "isSpoiler": isSpoiler,      // Bool 타입
                "lastValue": lastValue,      // String 또는 Double (서버 요구에 따라)
                "lastId": lastId,
                "size": size
            ]
        case let .registerRating(_, rating):
            return [
                "rating": rating
            ]
            
        case .studioDetailInfo(let studioId, let lastId, let lastValue, let size):
            <#code#>
        case .charactersDetailInfo(let animeId, let lastId, let lastValue, let size):
            <#code#>
        case .voiceActorDetailInfo(let personId, let lastId, let size):
            <#code#>
        case .recommendationAnime(let animeId, let lastId, let size):
            <#code#>
        case .writeAndEditReview(let animeId, let content, let rating, let isSpoiler):
            <#code#>
        case .seriesAnimeList(let animeId, let lastId, let size):
            <#code#>
        }

    }
    
    func asURLRequest() throws -> URLRequest {
        let url = try NetworkManager.baseUrl.asURL()
        var urlRequest = URLRequest(url: url.appendingPathComponent(self.path))
        urlRequest.httpMethod = self.method.rawValue
        
        switch self {
        case .animeDetailInfo:
            urlRequest = try URLEncoding.default.encode(urlRequest, with: self.parameters)
        case .animeDetailActorInfo:
            urlRequest = try URLEncoding.default.encode(urlRequest, with: self.parameters)
        case .studioDetailInfo:
            urlRequest = try URLEncoding.default.encode(urlRequest, with: self.parameters)
        case .animeDetailSeriesInfo(animeId: let animeId):
            urlRequest = try URLEncoding.default.encode(urlRequest, with: self.parameters)
            
        case .animeDetailRecommendation:
            urlRequest = try URLEncoding.default.encode(urlRequest, with: self.parameters)
            
        case .reviewList:
            urlRequest = try JSONEncoding.default.encode(urlRequest, with: self.parameters)
        case .registerRating:
            urlRequest = try JSONEncoding.default.encode(urlRequest, with: self.parameters)
            
            
            
            
        case .charactersDetailInfo(let animeId, let lastId, let lastValue, let size):
            <#code#>
        case .voiceActorDetailInfo(let personId, let lastId, let size):
            <#code#>
        case .recommendationAnime(let animeId, let lastId, let size):
            <#code#>
        case .writeAndEditReview(let animeId, let content, let rating, let isSpoiler):
            <#code#>
        case .seriesAnimeList(let animeId, let lastId, let size):
            <#code#>
            
            
        }
        return urlRequest
    }
    
    var header: HTTPHeaders {
        return ["Content-Type": "application/json",
                "Authorization": "Bearer \(UserDefaultsManager.shared.getAccessToken())"]
    }
}
