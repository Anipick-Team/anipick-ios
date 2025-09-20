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
    case reviewList(animeId: Int, sort: String, isSpoiler: Bool, lastValue: String?, lastId: Int?, size: Int?)
    case registerRating(animeId: Int, rating: Double)
    case editRating(reviewId: Int, rating: Double)
    case deleteRating(reviewId: Int)
    
    // 애니메이션 좋아요/취소
    case likeAnime(animeId: Int)
    case cancelLikeAnime(animeId: Int)
    
    // 애니 시청 기록
    case animeWatchingStatus(animeId: Int,  status: String) // WATCHLIST, WATCHING, FINISHED 중 하나
    case deleteAnimeWatchingStatus(animeId: Int)
    
    case studioDetailInfo(studioId: Int, lastId: Int?, lastValue: Int?, size: Int)
    case charactersDetailInfo(animeId: Int, lastId: Int?, lastValue: Int?, size: Int)
    
    case voiceActorDetailInfo(personId: Int, lastId: Int?, size: Int)
    case likePerson(personId: Int)
    case cancelLikePerson(personId: Int)
    
    case recommendationAnime(animeId: Int, lastId: Int?, size: Int?)
    
    
    case writeAndEditReview(animeId: Int, content: String, rating: Double, isSpoiler: Bool)
    case seriesAnimeList(animeId: Int, lastId: Int?, size: Int)
    
    // 회원가입 시 사용하는 애니평가
    case preference(query: String?, year: Int?, season: Int?, genre: Int?, lastId: Int?)
    case storedPreference(request: [AuthAnimeRatingRequest])
    
    
    // 홈화면의 공개예정
    case commingSoonInfo(sort: String, lastId: Int?, includeAdult: Bool, lastValue: String?)
    
    case myReview(animeId: Int)
    
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
        
            
        case let .reviewList(animeId, _, _, _, _, _):
            return "api/animes/\(animeId)/reviews"
        case let .registerRating(animeId, _):
            return "api/rating/\(animeId)/animes"
        case let .editRating(reviewId, _):
            return "api/rating/\(reviewId)/animes"
        case .deleteRating(let reviewId):
            return "api/rating/\(reviewId)/animes"
            
        case .likeAnime(let animeId):
            return "api/animes/\(animeId)/like"
        case .cancelLikeAnime(let animeId):
            return "api/animes/\(animeId)/like"
            
        case let .animeWatchingStatus(animeId, _):
            return "api/users/\(animeId)/status"
        case let .deleteAnimeWatchingStatus(animeId):
            return "api/users/\(animeId)/status"
            
        case let .studioDetailInfo(studioId, _, _, _):
            return "api/studios/\(studioId)/animes"
            
        case let .charactersDetailInfo(animeId, _, _, _):
            return "api/animes/\(animeId)/characters"
        case .voiceActorDetailInfo(let personId, let lastId, let size):
            return "api/person/\(personId)"
            
            
        case .likePerson(let personId):
            return "api/persons/\(personId)/like"
            
        case .cancelLikePerson(let personId):
            return "api/persons/\(personId)/like"
            
            
            
        case let .recommendationAnime(animeId, _, _):
           return "api/animes/\(animeId)/recommendations"
        case let .writeAndEditReview(animeId, _, _, _):
            return "api/reviews/\(animeId)/animes"
        case let .seriesAnimeList(animeId, lastId, size):
            return "api/animes/\(animeId)/series"
        case .preference:
            return "api/explore-search"
        case .storedPreference:
            return "api/reviews/bulk"
        case .commingSoonInfo:
            return "api/animes/coming-soon"
            
        case .myReview(let animeId):
            return "api/animes/\(animeId)/my-review"
            
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
        case .charactersDetailInfo:
            return .get
        case .voiceActorDetailInfo:
            return .get
        case .likePerson:
            return .post
        case .cancelLikePerson:
            return .delete
 
        case .recommendationAnime:
            return .get
        case .writeAndEditReview:
            return .patch
        case .seriesAnimeList:
            return .get
        case .preference:
            return .get
        case .storedPreference:
            return .post
        case .commingSoonInfo:
            return .get
            
        case .myReview:
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
            
        case let .reviewList(_, sort, isSpoiler, lastValue, lastId, _):
            let isSpoilerString = isSpoiler ? "true" : "false"
            let rawParams: [String : Any?] = [
                "sort": sort,//정렬 기준 (latest, likes, ratingDesc, ratingAsc)
                "isSpoiler": isSpoilerString,      // Bool 타입
                "lastValue": lastValue,      // String 또는 Double (서버 요구에 따라)
                "lastId": lastId,
                "size": 10
            ]
            
            return rawParams.compactMapValues { $0 }
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
            
            
            
        case .likeAnime(let animeId):
            return [
                "animeId": animeId
            ]
        case .cancelLikeAnime:
            return nil
            
        case let .animeWatchingStatus(_, status):
            return [
                "status": status
            ]
        case .deleteAnimeWatchingStatus:
            return nil
            
            
        case .studioDetailInfo(let studioId, let lastId, let lastValue, let size):
            let rawParams: [String: Any?] = [
                "lastId": lastId,
                "lastValue": lastValue,
                "size": size
            ]
            
            return rawParams.compactMapValues { $0 }
        case .charactersDetailInfo(let animeId, let lastId, let lastValue, let size):
            let rawParams: [String: Any?] = [
                "lastId": lastId,
                "lastValue": lastValue,
                "size": size
            ]
            
            return rawParams.compactMapValues { $0 }
        case .voiceActorDetailInfo(let personId, let lastId, let size):
            let rawParams: [String: Any?] = [
                "lastId": lastId,
                "size": size
            ]
            return rawParams.compactMapValues { $0 }
            
        case .likePerson:
            return nil
        case .cancelLikePerson:
            return nil
            
            
            
        case let .recommendationAnime(_, lastId, _):
            let rawParams = [
                "lastId": lastId,
                "size": 10
            ]
            return rawParams.compactMapValues { $0 }
        case let .writeAndEditReview(_, content, rating, isSpoiler):
            return [
                "rating": rating,
                "isSpoiler": isSpoiler,
                "content": content
            ]
            
        case let .seriesAnimeList(_, lastId, size):
            let rawParams = [
                "lastId": lastId,
                "size": 10
            ]
            return rawParams.compactMapValues { $0 }
            
        case let .preference(query, year, season, genre, lastId):
            let rawParams: [String: Any?] = [
            "query": query,
            "year": year,
            "season": season, // 예: "spring", "summer", "fall", "winter"
            "genres": genre,
            "lastId": lastId
           ]
            return rawParams.compactMapValues { $0 }
        case .storedPreference:
            // TODO: 배열로 선택한 값 넣는 것 필요함~~
            /*
             let ratedAnimes: [[String: Any]] = [
                 ["animeId": 12345, "rating": 4.5],
                 ["animeId": 54321, "rating": 5.0]
             ]

             let parameters: [String: Any] = [
                 "ratedAnimes": ratedAnimes
             ]

             */
            return nil
            
        case let .commingSoonInfo(sort, lastId, includeAdult, lastValue):
            let adult = includeAdult ? "true" : "false"
            let rawParams: [String: Any?] = [
                    "sort": sort,
                    "lastId": lastId,
                    "size": 18,
                    "includeAdult": adult,
                    "lastValue": lastValue
                ]
                return rawParams.compactMapValues { $0 }
            
        case .myReview:
            return nil
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
            urlRequest = try URLEncoding.default.encode(urlRequest, with: self.parameters)
        case .registerRating:
            urlRequest = try JSONEncoding.default.encode(urlRequest, with: self.parameters)
        case .editRating:
            urlRequest = try JSONEncoding.default.encode(urlRequest, with: self.parameters)
        case .deleteRating:
            urlRequest = try URLEncoding.default.encode(urlRequest, with: self.parameters)
            
            
        case .likeAnime:
            urlRequest = try JSONEncoding.default.encode(urlRequest, with: self.parameters)
        case .cancelLikeAnime:
            urlRequest = try URLEncoding.default.encode(urlRequest, with: self.parameters)
            
            
        case .animeWatchingStatus:
            urlRequest = try JSONEncoding.default.encode(urlRequest, with: self.parameters)
        case .deleteAnimeWatchingStatus:
            urlRequest = try URLEncoding.default.encode(urlRequest, with: self.parameters)
            
        case .charactersDetailInfo:
            urlRequest = try URLEncoding.default.encode(urlRequest, with: self.parameters)
            
            
            
        case .voiceActorDetailInfo:
            urlRequest = try URLEncoding.default.encode(urlRequest, with: self.parameters)
        case .likePerson:
            urlRequest = try URLEncoding.default.encode(urlRequest, with: self.parameters)
        case .cancelLikePerson:
            urlRequest = try URLEncoding.default.encode(urlRequest, with: self.parameters)
            
            
            
            
        case .recommendationAnime:
            urlRequest = try URLEncoding.default.encode(urlRequest, with: self.parameters)
        case .writeAndEditReview:
            urlRequest = try JSONEncoding.default.encode(urlRequest, with: self.parameters)
        case .seriesAnimeList:
            urlRequest = try URLEncoding.default.encode(urlRequest, with: self.parameters)
            
        case .preference:
            urlRequest = try URLEncoding.default.encode(urlRequest, with: self.parameters)
        case let .storedPreference(request):
            urlRequest.httpBody = try JSONEncoder().encode(request)
            urlRequest = try JSONEncoding.default.encode(urlRequest, with: self.parameters)
            
        case .commingSoonInfo:
            urlRequest = try URLEncoding.default.encode(urlRequest, with: self.parameters)
            
        case .myReview:
            urlRequest = try URLEncoding.default.encode(urlRequest, with: self.parameters)
            
            
            
        }
   
        
        
        for key in headers.dictionary.keys {
            if let value = headers[key] {
                urlRequest.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        return urlRequest
    }
    
    var headers: HTTPHeaders {
        return ["Content-Type": "application/json",
                "Authorization": "Bearer \(UserDefaultsManager.shared.getAccessToken())"]
    }
}
