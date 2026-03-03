import Foundation

/// TV 아사히 크롤링 JSON을 받아오는 API.
/// - **한국어 번역본(_kr.json)** 로드. HoroscopeBaseURL 또는 번들 data/ 폴더에서 가져옵니다.
/// - baseURL: Info "HoroscopeBaseURL" (예: https://raw.githubusercontent.com/.../data)
/// 생성 파일: data/{날짜}_jp.json, data/{날짜}_kr.json (크롤러가 저장)

struct HoroscopeAPI {
    static let shared = HoroscopeAPI()

    private static let kst = TimeZone(identifier: "Asia/Seoul")!

    private static let kstDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = kst
        return f
    }()

    /// KST 기준 오늘 날짜 문자열 (yyyy-MM-dd)
    static var todayDateStringKST: String {
        kstDateFormatter.string(from: Date())
    }

    /// KST 기준 어제 날짜 문자열 (6:30 이전 오늘 데이터 없을 때 폴백용)
    static var yesterdayDateStringKST: String {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = kst
        let yesterday = cal.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        return kstDateFormatter.string(from: yesterday)
    }

    /// KST 기준 어제 Date (폴백용)
    static var yesterdayDateKST: Date {
        kstDateFormatter.date(from: yesterdayDateStringKST) ?? Date()
    }

    /// KST 기준 오늘 Date (payload용, 해당 날짜 00:00 KST)
    static var todayDateKST: Date {
        kstDateFormatter.date(from: todayDateStringKST) ?? Date()
    }

    /// KST 기준 현재 시각이 6:30 이후인지 (새 데이터 수집 가능 시점)
    static var isPastCrawlTimeKST: Bool {
        var cal = Calendar.current
        cal.timeZone = kst
        let now = Date()
        let hour = cal.component(.hour, from: now)
        let minute = cal.component(.minute, from: now)
        return hour > 6 || (hour == 6 && minute >= 30)
    }

    /// Info.plist "HoroscopeBaseURL" 또는 기본값. 끝에 슬래시 없이 (예: https://example.com/data)
    private var baseURL: URL {
        if let s = Bundle.main.object(forInfoDictionaryKey: "HoroscopeBaseURL") as? String,
           let url = URL(string: s), url.scheme != nil {
            return url
        }
        return URL(string: "https://example.com/horoscope")!
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    /// 오늘 날짜 **한국어 번역본** (_kr.json). KST 기준 오늘. 실패 시 nil.
    func fetchTodayKorean() async throws -> HoroscopeDayPayload {
        try await fetchKoreanForDateKST(Self.todayDateStringKST, cacheBust: Self.isPastCrawlTimeKST)
    }

    /// KST 날짜 문자열로 한국어 로드 (오늘용). 네트워크 → 번들.
    private func fetchKoreanForDateKST(_ dateString: String, cacheBust: Bool = false) async throws -> HoroscopeDayPayload {
        let fileName = "\(dateString)_kr.json"
        let date = Self.kstDateFormatter.date(from: dateString) ?? Self.todayDateKST

        if let payload = try? await fetchFromNetwork(path: fileName, date: date, cacheBust: cacheBust) {
            return payload
        }
        if let payload = try? fetchFromBundle(fileName: fileName, date: date) {
            return payload
        }
        throw URLError(.resourceUnavailable)
    }

    /// 지정 날짜 **한국어 번역본** (_kr.json). 네트워크 실패 시 번들 data/ 폴더에서 시도.
    func fetchKorean(for date: Date, cacheBust: Bool = false) async throws -> HoroscopeDayPayload {
        let dateString = Self.dateFormatter.string(from: date)
        return try await fetchKoreanForDateKST(dateString, cacheBust: cacheBust)
    }

    private func fetchFromNetwork(path: String, date: Date, cacheBust: Bool = false) async throws -> HoroscopeDayPayload {
        var url = baseURL.appendingPathComponent(path)
        if cacheBust {
            var comp = URLComponents(url: url, resolvingAgainstBaseURL: false)
            comp?.queryItems = [URLQueryItem(name: "t", value: "\(Int(Date().timeIntervalSince1970))")]
            if let cached = comp?.url { url = cached }
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        return try decodePayload(data, date: date)
    }

    /// 앱 번들 내 data/ 폴더의 JSON (크롤러로 생성 후 data를 리소스로 넣었을 때)
    private func fetchFromBundle(fileName: String, date: Date) throws -> HoroscopeDayPayload? {
        let name = (fileName as NSString).deletingPathExtension
        guard let url = Bundle.main.url(forResource: name, withExtension: "json", subdirectory: "data"),
              let data = try? Data(contentsOf: url) else { return nil }
        return try? decodePayload(data, date: date)
    }

    private func decodePayload(_ data: Data, date: Date) throws -> HoroscopeDayPayload {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(Self.dateFormatter)
        return try decoder.decode(HoroscopeDayPayload.self, from: data)
    }
}

