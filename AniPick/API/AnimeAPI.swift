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
    case editRating(reviewId: Int, rating: Double)
    case deleteRating(reviewId: Int)
    
    // 애니메이션 좋아요/취소
    case likeAnime(animeId: Int)
    case cancelLikeAnime(animeId: Int)
    
    // 애니 시청 기록
    case animeWatchingStatus(animeId: Int,  status: String) // WATCHLIST, WATCHING, FINISHED 중 하나
    case deleteAnimeWatchingStatus(animeId: Int)
    
    case studioDetailInfo(studioId: Int, lastId: Int, lastValue: Int, size: Int)
    case charactersDetailInfo(animeId: Int, lastId: Int, lastValue: Int, size: Int)
    
    case voiceActorDetailInfo(personId: Int, lastId: Int, size: Int)
    case likePerson(personId: Int)
    case cancelLikePerson(personId: Int)
    
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
        case let .editRating(reviewId, _):
            return "api/rating/\(reviewId)/animes"
        case .deleteRating(let reviewId):
            return "api/rating/\(reviewId)/animes"
            
        case .likeAnime(let animeId):
            return "api/animes/{animeId}/like"
        case .cancelLikeAnime(let animeId):
            return "api/animes/{animeId}/like"
            
        case let .animeWatchingStatus(animeId, _):
            return "api/users/\(animeId)/status"
        case let .deleteAnimeWatchingStatus(animeId):
            return "api/users/\(animeId)/status"
            
        case .studioDetailInfo(let studioId, let lastId, let lastValue, let size):
            return "api/studios/\(studioId)/animes"
            
        case .charactersDetailInfo(let animeId, let lastId, let lastValue, let size):
            return "api/animes/\(animeId)/characters"
        case .voiceActorDetailInfo(let personId, let lastId, let size):
            return "api/person/\(personId)"
            
            
        case .likePerson(let personId):
            return "api/persons/\(personId)/like"
            
        case .cancelLikePerson(let personId):
            return "api/persons/\(personId)/like"
            
            
            
        case .recommendationAnime(let animeId, let lastId, let size):
           return "api/animes/\(animeId)/recommendations"
        case .writeAndEditReview(let animeId, let content, let rating, let isSpoiler):
            return "api/reviews/\(animeId)/animes"
        case .seriesAnimeList(let animeId, let lastId, let size):
            return "api/animes/\(animeId)/series"
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
        case .editRating:
            return .patch
        case .deleteRating:
            return .delete
            
            
        case .likeAnime:
            return .post
        case .cancelLikeAnime:
            return .delete
            
            
        case .animeWatchingStatus:
            return .post
        case .deleteAnimeWatchingStatus:
            return .delete
            
        case .studioDetailInfo:
            return .get
        case .charactersDetailInfo(let animeId, let lastId, let lastValue, let size):
            return .get
        case .voiceActorDetailInfo:
            return .get
        case .likePerson:
            return .post
        case .cancelLikePerson:
            return .delete
 
        case .recommendationAnime(let animeId, let lastId, let size):
            return .get
        case .writeAndEditReview(let animeId, let content, let rating, let isSpoiler):
            return .patch
        case .seriesAnimeList(let animeId, let lastId, let size):
            return .get
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
            
        case let .editRating(_, rating):
            return [
                "rating": rating
            ]
            
        case let .deleteRating:
            return nil
            
            
            
        case .likeAnime:
            return nil
        case .cancelLikeAnime:
            return nil
            
        case let .animeWatchingStatus(_, status):
            return [
                "status": status
            ]
        case .deleteAnimeWatchingStatus:
            return nil
            
            
        case .studioDetailInfo(let studioId, let lastId, let lastValue, let size):
            return [
                "lastId": lastId,
                "lastValue": lastValue,
                "size": size
            ]
            
        case .charactersDetailInfo(let animeId, let lastId, let lastValue, let size):
            return [
                "lastId": lastId,
                "lastValue": lastValue,
                "size": size
            ]
        case .voiceActorDetailInfo(let personId, let lastId, let size):
            return [
                "lastId": lastId,
                "size": size
            ]
            
        case .likePerson:
            return nil
        case .cancelLikePerson:
            return nil
            
            
            
        case .recommendationAnime(let animeId, let lastId, let size):
            return [
                "lastId": lastId,
                "size": size
            ]
        case .writeAndEditReview(let animeId, let content, let rating, let isSpoiler):
            return [
                "content": content,
                "rating": rating,
                "isSpoiler": isSpoiler
            ]
        case .seriesAnimeList(let animeId, let lastId, let size):
            return [
                "lastId": lastId,
                "size": size
            ]
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
        case .editRating:
            urlRequest = try JSONEncoding.default.encode(urlRequest, with: self.parameters)
        case .deleteRating:
            urlRequest = try URLEncoding.default.encode(urlRequest, with: self.parameters)
            
            
        case .likeAnime:
            urlRequest = try URLEncoding.default.encode(urlRequest, with: self.parameters)
        case .cancelLikeAnime:
            urlRequest = try URLEncoding.default.encode(urlRequest, with: self.parameters)
            
            
        case .animeWatchingStatus:
            urlRequest = try JSONEncoding.default.encode(urlRequest, with: self.parameters)
        case .deleteAnimeWatchingStatus:
            urlRequest = try URLEncoding.default.encode(urlRequest, with: self.parameters)
            
        case .charactersDetailInfo:
            urlRequest = try JSONEncoding.default.encode(urlRequest, with: self.parameters)
            
            
            
        case .voiceActorDetailInfo(let personId, let lastId, let size):
            urlRequest = try JSONEncoding.default.encode(urlRequest, with: self.parameters)
        case .likePerson:
            urlRequest = try URLEncoding.default.encode(urlRequest, with: self.parameters)
        case .cancelLikePerson:
            urlRequest = try URLEncoding.default.encode(urlRequest, with: self.parameters)
            
            
            
            
        case .recommendationAnime(let animeId, let lastId, let size):
            urlRequest = try JSONEncoding.default.encode(urlRequest, with: self.parameters)
        case .writeAndEditReview(let animeId, let content, let rating, let isSpoiler):
            urlRequest = try JSONEncoding.default.encode(urlRequest, with: self.parameters)
        case .seriesAnimeList(let animeId, let lastId, let size):
            urlRequest = try JSONEncoding.default.encode(urlRequest, with: self.parameters)
            
            
        }
        return urlRequest
    }
    
    var header: HTTPHeaders {
        return ["Content-Type": "application/json",
                "Authorization": "Bearer \(UserDefaultsManager.shared.getAccessToken())"]
    }
}
