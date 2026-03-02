import Foundation

/// TV 아사히 크롤링 JSON을 받아오는 API.
/// - **한국어 번역본(_kr.json)** 우선 로드. 없으면 **번역 서버**(HoroscopeTranslateURL)로 일본어 전송 후 한국어 수신.
/// - 번역 서버는 OpenAI API 키를 서버에만 두고, 앱에는 API 키를 넣지 않습니다.
/// - HoroscopeTranslateURL: 번역 백엔드 기본 URL (예: https://your-app.run.app). 설정 시 한국어 없을 때만 사용.
/// - HoroscopeAppSecret (선택): 서버가 검증용으로 사용하는 값과 동일하게 설정. 앱이 X-App-Secret으로 전송.
/// - baseURL: Xcode 타깃 → Info → Custom iOS Target Properties 에서 "HoroscopeBaseURL" (String) 추가 후
///   data 폴더를 서빙하는 URL 입력 (끝에 슬래시 없이, 예: https://yourserver.com/data).
/// - 설정하지 않으면 번들 리소스 data/ 폴더에서만 로드 시도.
/// 생성 파일: data/{날짜}_jp.json, data/{날짜}_kr.json (크롤러가 저장)

struct HoroscopeAPI {
    static let shared = HoroscopeAPI()

    /// Info.plist "HoroscopeBaseURL" 또는 기본값. 끝에 슬래시 없이 (예: https://example.com/data)
    private var baseURL: URL {
        if let s = Bundle.main.object(forInfoDictionaryKey: "HoroscopeBaseURL") as? String,
           let url = URL(string: s), url.scheme != nil {
            return url
        }
        return URL(string: "https://example.com/horoscope")!
    }

    /// 번역 백엔드 URL. HTTPS만 허용. 설정 시 한국어 없을 때 일본어를 이 서버로 보내 한국어 수신.
    private var translateBaseURL: URL? {
        guard let s = Bundle.main.object(forInfoDictionaryKey: "HoroscopeTranslateURL") as? String,
              let url = URL(string: s), url.scheme == "https" else { return nil }
        return url
    }

    /// 서버 검증용 시크릿. Info "HoroscopeAppSecret"에 설정 시 X-App-Secret 헤더로 전송. (OpenAI 키 아님)
    private var appSecret: String? {
        Bundle.main.object(forInfoDictionaryKey: "HoroscopeAppSecret") as? String
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    /// 오늘 날짜 **한국어 번역본** (_kr.json). 실패 시 nil.
    func fetchTodayKorean() async throws -> HoroscopeDayPayload {
        try await fetchKorean(for: Date())
    }

    /// 일본어 페이로드를 번역 서버로 보내 한국어 페이로드를 받습니다. (API 키는 앱에 없음)
    func fetchKoreanViaTranslate(japanesePayload: HoroscopeDayPayload) async throws -> HoroscopeDayPayload {
        guard let base = translateBaseURL else {
            throw URLError(.resourceUnavailable)
        }
        let url = base.appendingPathComponent("v1/translate")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let secret = appSecret, !secret.isEmpty {
            request.setValue(secret, forHTTPHeaderField: "X-App-Secret")
        }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .formatted(Self.dateFormatter)
        request.httpBody = try encoder.encode(japanesePayload)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        switch http.statusCode {
        case 200:
            return try decodePayload(data, date: japanesePayload.date)
        case 401:
            throw URLError(.userAuthenticationRequired)
        case 429:
            throw URLError(.resourceUnavailable)
        case 502, 503:
            throw URLError(.badServerResponse)
        default:
            throw URLError(.badServerResponse)
        }
    }

    /// 지정 날짜 **한국어 번역본** (_kr.json). 네트워크 실패 시 번들 data/ 폴더에서 시도.
    func fetchKorean(for date: Date) async throws -> HoroscopeDayPayload {
        let dateString = Self.dateFormatter.string(from: date)
        let fileName = "\(dateString)_kr.json"

        if let payload = try? await fetchFromNetwork(path: fileName, date: date) {
            return payload
        }
        if let payload = try? fetchFromBundle(fileName: fileName, date: date) {
            return payload
        }
        throw URLError(.resourceUnavailable)
    }

    /// 오늘 날짜 **일본어 원문** (_jp.json). 번역본 없을 때 앱 내 번역용.
    func fetchTodayJapanese() async throws -> HoroscopeDayPayload {
        try await fetchJapanese(for: Date())
    }

    /// 지정 날짜 일본어 원문 (_jp.json). 네트워크 실패 시 번들에서 시도.
    func fetchJapanese(for date: Date) async throws -> HoroscopeDayPayload {
        let dateString = Self.dateFormatter.string(from: date)
        let fileName = "\(dateString)_jp.json"

        if let payload = try? await fetchFromNetwork(path: fileName, date: date) {
            return payload
        }
        if let payload = try? fetchFromBundle(fileName: fileName, date: date) {
            return payload
        }
        throw URLError(.resourceUnavailable)
    }

    private func fetchFromNetwork(path: String, date: Date) async throws -> HoroscopeDayPayload {
        let url = baseURL.appendingPathComponent(path)
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

