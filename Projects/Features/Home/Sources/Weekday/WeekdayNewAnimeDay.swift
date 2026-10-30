import Foundation

/// 요일 (월=1 … 일=7). 레거시 `WeekdayNewAnimeDay`
enum WeekdayNewAnimeDay: Int, CaseIterable, Identifiable, Sendable {
    case monday = 1
    case tuesday, wednesday, thursday, friday, saturday, sunday

    var id: Int {
        return rawValue
    }

    var title: String {
        switch self {
        case .monday:
            return "월"
        case .tuesday:
            return "화"
        case .wednesday:
            return "수"
        case .thursday:
            return "목"
        case .friday:
            return "금"
        case .saturday:
            return "토"
        case .sunday:
            return "일"
        }
    }

    /// 서버 `GET api/animes`의 `day` 파라미터 (MON~SUN)
    var apiValue: String {
        switch self {
        case .monday:
            return "MON"
        case .tuesday:
            return "TUE"
        case .wednesday:
            return "WED"
        case .thursday:
            return "THU"
        case .friday:
            return "FRI"
        case .saturday:
            return "SAT"
        case .sunday:
            return "SUN"
        }
    }

    /// 월요일 앞·일요일 뒤는 없다 (넘어가지 않는다)
    var previous: WeekdayNewAnimeDay? {
        return WeekdayNewAnimeDay(rawValue: rawValue - 1)
    }

    var next: WeekdayNewAnimeDay? {
        return WeekdayNewAnimeDay(rawValue: rawValue + 1)
    }

    /// Calendar의 일=1 … 토=7을 월=1 … 일=7로
    static func of(_ date: Date, calendar: Calendar = .current) -> WeekdayNewAnimeDay {
        let weekday = calendar.component(.weekday, from: date)
        return WeekdayNewAnimeDay(rawValue: weekday == 1 ? 7 : weekday - 1) ?? .monday
    }
}
