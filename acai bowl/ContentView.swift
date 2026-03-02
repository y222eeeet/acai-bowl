//
//  ContentView.swift
//  acai bowl
//
//  Created by 서지우 on 3/1/26.
//

import SwiftUI

enum ZodiacSign: String, CaseIterable, Identifiable, Codable {
    case aries = "양자리"
    case taurus = "황소자리"
    case gemini = "쌍둥이자리"
    case cancer = "게자리"
    case leo = "사자자리"
    case virgo = "처녀자리"
    case libra = "천칭자리"
    case scorpio = "전갈자리"
    case sagittarius = "사수자리"
    case capricorn = "염소자리"
    case aquarius = "물병자리"
    case pisces = "물고기자리"

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .aries: return "🐏"
        case .taurus: return "🐂"
        case .gemini: return "👯"
        case .cancer: return "🦀"
        case .leo: return "🦁"
        case .virgo: return "🌾"
        case .libra: return "⚖️"
        case .scorpio: return "🦂"
        case .sagittarius: return "🏹"
        case .capricorn: return "🐐"
        case .aquarius: return "🏺"
        case .pisces: return "🐟"
        }
    }
}

struct DailyHoroscope: Identifiable, Codable {
    let id = UUID()
    let date: Date
    let sign: ZodiacSign
    let rank: Int
    let shortMessage: String
    let detail: String
    let luckyColor: String
    let luckyItem: String
    let moneyScore: Int
    let loveScore: Int
    let workScore: Int
    let healthScore: Int

    private enum CodingKeys: String, CodingKey {
        case date
        case sign
        case rank
        case shortMessage
        case detail
        case luckyColor
        case luckyItem
        case moneyScore
        case loveScore
        case workScore
        case healthScore
    }

    init(
        date: Date,
        sign: ZodiacSign,
        rank: Int,
        shortMessage: String,
        detail: String,
        luckyColor: String,
        luckyItem: String,
        moneyScore: Int = 0,
        loveScore: Int = 0,
        workScore: Int = 0,
        healthScore: Int = 0
    ) {
        self.date = date
        self.sign = sign
        self.rank = rank
        self.shortMessage = shortMessage
        self.detail = detail
        self.luckyColor = luckyColor
        self.luckyItem = luckyItem
        self.moneyScore = moneyScore
        self.loveScore = loveScore
        self.workScore = workScore
        self.healthScore = healthScore
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        date = try container.decode(Date.self, forKey: .date)
        sign = try container.decode(ZodiacSign.self, forKey: .sign)
        rank = try container.decode(Int.self, forKey: .rank)
        shortMessage = try container.decode(String.self, forKey: .shortMessage)
        detail = try container.decode(String.self, forKey: .detail)
        luckyColor = try container.decode(String.self, forKey: .luckyColor)
        luckyItem = try container.decode(String.self, forKey: .luckyItem)
        moneyScore = try container.decodeIfPresent(Int.self, forKey: .moneyScore) ?? 0
        loveScore = try container.decodeIfPresent(Int.self, forKey: .loveScore) ?? 0
        workScore = try container.decodeIfPresent(Int.self, forKey: .workScore) ?? 0
        healthScore = try container.decodeIfPresent(Int.self, forKey: .healthScore) ?? 0
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(date, forKey: .date)
        try container.encode(sign, forKey: .sign)
        try container.encode(rank, forKey: .rank)
        try container.encode(shortMessage, forKey: .shortMessage)
        try container.encode(detail, forKey: .detail)
        try container.encode(luckyColor, forKey: .luckyColor)
        try container.encode(luckyItem, forKey: .luckyItem)
        try container.encode(moneyScore, forKey: .moneyScore)
        try container.encode(loveScore, forKey: .loveScore)
        try container.encode(workScore, forKey: .workScore)
        try container.encode(healthScore, forKey: .healthScore)
    }
}

struct HoroscopeDayPayload: Codable {
    let date: Date
    let items: [DailyHoroscope]
}

// MARK: - 더미 리포지토리

protocol HoroscopeRepository {
    func todayPayload() -> HoroscopeDayPayload
}

struct DummyHoroscopeRepository: HoroscopeRepository {
    static let shared = DummyHoroscopeRepository()

    func todayPayload() -> HoroscopeDayPayload {
        let today = Date()

        let baseMessages: [(ZodiacSign, String, String, String, String)] = [
            (.aries, "에너지가 넘치는 하루예요.", "도전적인 일에 운이 따릅니다. 새로운 일을 시작해 보세요.", "레드", "새 노트"),
            (.taurus, "안정감이 중요한 날입니다.", "루틴을 유지하면 마음이 편안해집니다.", "브라운", "따뜻한 커피"),
            (.gemini, "소통 운이 좋은 날이에요.", "연락이 끊겼던 사람에게 먼저 연락해 보세요.", "옐로우", "이어폰"),
            (.cancer, "집과 안락함이 키워드입니다.", "집에서 보내는 시간이 힐링이 됩니다.", "라이트 블루", "포근한 담요"),
            (.leo, "스포트라이트가 당신에게 향합니다.", "자신감을 가지고 나를 표현해 보세요.", "골드", "반짝이는 액세서리"),
            (.virgo, "정리 정돈에 좋은 날이에요.", "작은 정리가 생각보다 큰 리프레시를 줍니다.", "네이비", "플래너"),
            (.libra, "밸런스가 중요해요.", "일과 휴식의 균형을 의식적으로 잡아보세요.", "핑크", "향 좋은 핸드크림"),
            (.scorpio, "집중력이 올라가는 날입니다.", "몰입이 필요한 일을 처리하기에 좋아요.", "딥 퍼플", "노이즈 캔슬링"),
            (.sagittarius, "모험심이 살아나는 날이에요.", "평소 안 하던 선택을 해보는 것도 좋아요.", "오렌지", "새로운 길 산책"),
            (.capricorn, "성실함이 빛나는 하루입니다.", "조용히 할 일을 해내는 성취감을 느낄 수 있어요.", "그레이", "깔끔한 다이어리"),
            (.aquarius, "아이디어가 샘솟는 날이에요.", "번뜩이는 생각을 메모해 두세요.", "민트", "메모장"),
            (.pisces, "감성이 풍부해지는 날입니다.", "좋아하는 음악이나 영화를 즐겨보세요.", "라벤더", "이어폰 케이스")
        ]

        let items = baseMessages.enumerated().map { index, element in
            DailyHoroscope(
                date: today,
                sign: element.0,
                rank: index + 1,
                shortMessage: element.1,
                detail: element.2,
                luckyColor: element.3,
                luckyItem: element.4,
                moneyScore: 3,
                loveScore: 3,
                workScore: 3,
                healthScore: 3
            )
        }

        return HoroscopeDayPayload(date: today, items: items)
    }
}

// MARK: - 루트 뷰

struct ContentView: View {
    var body: some View {
        RootTabView()
    }
}

struct RootTabView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var selectedTab: Int = 1
    @StateObject private var horoscopeStore = HoroscopeTranslationStore()
    @AppStorage("selectedZodiac") private var selectedZodiacRaw: String = ZodiacSign.aries.rawValue

    var body: some View {
        TabView(selection: $selectedTab) {
            AllRankingView()
                .tabItem {
                    Label("전체 순위", systemImage: "list.number")
                }
                .tag(0)

            TodayHoroscopeView()
                .tabItem {
                    Label("오늘 운세", systemImage: "sun.max")
                }
                .tag(1)

            SettingsView()
                .tabItem {
                    Label("설정", systemImage: "gearshape")
                }
                .tag(2)
        }
        .environmentObject(horoscopeStore)
        .task {
            await horoscopeStore.load()
            updateWidgetAfterLoad()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                Task { await horoscopeStore.load(); updateWidgetAfterLoad() }
            }
        }
        .task(id: scenePhase) {
            guard scenePhase == .active else { return }
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(60 * 15))
                guard !Task.isCancelled else { break }
                if HoroscopeAPI.isPastCrawlTimeKST {
                    await horoscopeStore.load()
                    updateWidgetAfterLoad()
                }
            }
        }
        .onChange(of: selectedZodiacRaw) { _, _ in
            updateWidgetAfterLoad()
        }
    }

    private func updateWidgetAfterLoad() {
        let sign = ZodiacSign(rawValue: selectedZodiacRaw) ?? .aries
        if let horoscope = horoscopeStore.payload.items.first(where: { $0.sign == sign }) {
            WidgetDataManager.update(
                selectedZodiac: selectedZodiacRaw,
                zodiacEmoji: horoscope.sign.emoji,
                rank: horoscope.rank,
                shortMessage: horoscope.shortMessage,
                detail: horoscope.detail
            )
        } else {
            WidgetDataManager.updateSelectedZodiacOnly(selectedZodiacRaw)
        }
    }
}

// MARK: - 탭 1: 전체 순위

struct AllRankingView: View {
    @EnvironmentObject private var horoscopeStore: HoroscopeTranslationStore
    @State private var selectedHoroscope: DailyHoroscope?

    private var payload: HoroscopeDayPayload { horoscopeStore.payload }
    private var sortedItems: [DailyHoroscope] { payload.items.sorted { $0.rank < $1.rank } }

    var body: some View {
        NavigationStack {
            List(sortedItems) { item in
                Button {
                    selectedHoroscope = item
                } label: {
                    HStack(spacing: 12) {
                        Text("\(item.rank)")
                            .font(.title3.bold())
                            .frame(width: 32)

                        Text(item.sign.emoji)
                            .font(.title2)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.sign.rawValue)
                                .font(.headline)
                            Text(item.shortMessage)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }

                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("오늘 전체 별자리 순위")
            .sheet(item: $selectedHoroscope) { horoscope in
                NavigationStack {
                    HoroscopeDetailView(horoscope: horoscope)
                }
                .presentationDetents([.fraction(0.85), .large])
                .presentationDragIndicator(.visible)
                .presentationBackground(Color.white)
            }
        }
    }
}

// MARK: - 탭 2: 오늘 운세

struct TodayHoroscopeView: View {
    @AppStorage("selectedZodiac") private var selectedZodiacRaw: String = ZodiacSign.aries.rawValue
    @EnvironmentObject private var horoscopeStore: HoroscopeTranslationStore

    private var selectedSign: ZodiacSign {
        ZodiacSign(rawValue: selectedZodiacRaw) ?? .aries
    }

    private var payload: HoroscopeDayPayload { horoscopeStore.payload }

    var body: some View {
        NavigationStack {
            if let horoscope = payload.items.first(where: { $0.sign == selectedSign }) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        header(horoscope: horoscope)
                        Divider()
                        detailSection(horoscope: horoscope)
                        Divider()
                        luckySection(horoscope: horoscope)
                    }
                    .padding()
                }
                .navigationTitle("오늘의 운세")
                .onAppear { updateWidgetData(horoscope: horoscope) }
                .onChange(of: selectedZodiacRaw) { _, _ in
                    if let h = payload.items.first(where: { $0.sign == selectedSign }) {
                        updateWidgetData(horoscope: h)
                    }
                }
            } else {
                VStack(spacing: 16) {
                    Text("오늘 운세 데이터를 찾지 못했어요.")
                    Text("잠시 후 다시 시도해 주세요.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
        }
    }

    private func updateWidgetData(horoscope: DailyHoroscope) {
        WidgetDataManager.update(
            selectedZodiac: selectedZodiacRaw,
            zodiacEmoji: horoscope.sign.emoji,
            rank: horoscope.rank,
            shortMessage: horoscope.shortMessage,
            detail: horoscope.detail
        )
    }

    private func header(horoscope: DailyHoroscope) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(formattedDate(horoscope.date))
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack(spacing: 12) {
                Text(horoscope.sign.emoji)
                    .font(.system(size: 48))

                VStack(alignment: .leading, spacing: 4) {
                    Text(horoscope.sign.rawValue)
                        .font(.title2.bold())
                    Text("오늘의 순위 \(horoscope.rank)위")
                        .font(.headline)
                        .foregroundColor(.blue)
                }
            }

            Text("한줄평")
                .font(.headline)
            Text(horoscope.shortMessage)
                .font(.body)
        }
    }

    private func detailSection(horoscope: DailyHoroscope) -> some View {
        let lines = detailSentences(from: horoscope.detail)
        return VStack(alignment: .leading, spacing: 8) {
            Text("자세한 설명")
                .font(.headline)
            if lines.isEmpty {
                Text(horoscope.detail)
                    .font(.body)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                        Text(line)
                            .font(.body)
                    }
                }
            }
        }
    }

    private func luckySection(horoscope: DailyHoroscope) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("행운 요소")
                .font(.headline)
            scoreRow(for: horoscope, font: .caption)
            HStack {
                VStack(alignment: .leading) {
                    Text("행운 컬러")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    HStack(spacing: 8) {
                        luckyColorSwatch(horoscope.luckyColor)
                        Text(horoscope.luckyColor)
                            .font(.body)
                            .foregroundColor(.primary)
                    }
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("행운 아이템")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(horoscope.luckyItem)
                        .font(.body)
                }
            }
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 M월 d일 EEEE"
        return formatter.string(from: date)
    }
}

// 공통 운세 점수 뷰

@ViewBuilder
private func scoreRow(for horoscope: DailyHoroscope, font: Font) -> some View {
    VStack(alignment: .leading, spacing: 4) {
        scoreItem(label: "재물", emoji: "💰", score: horoscope.moneyScore)
        scoreItem(label: "애정", emoji: "❤️", score: horoscope.loveScore)
        scoreItem(label: "일·학업", emoji: "💼", score: horoscope.workScore)
        scoreItem(label: "건강", emoji: "💊", score: horoscope.healthScore)
    }
    .font(font)
    .foregroundColor(.secondary)
}

@ViewBuilder
private func scoreItem(label: String, emoji: String, score: Int) -> some View {
    let clamped = max(0, min(score, 5))
    HStack(spacing: 4) {
        Text(label)
        if clamped > 0 {
            Text(String(repeating: emoji, count: clamped))
        }
    }
}

/// 밝은 색(흰색, 베이지 등)인지. 흰 배경에서 테두리 필요 여부 판단.
private func isLightColor(_ name: String) -> Bool {
    let n = name.trimmingCharacters(in: .whitespaces).lowercased()
    switch n {
    case "흰색", "화이트", "white",
         "베이지", "beige",
         "은색", "실버", "silver",
         "민트", "mint",
         "하늘색", "스카이블루", "sky", "light blue", "물색", "水色":
        return true
    default:
        return false
    }
}

/// 행운 컬러 스워치(작은 색상 박스). 밝은 색은 테두리로 구분.
@ViewBuilder
private func luckyColorSwatch(_ name: String) -> some View {
    let color = colorFromName(name) ?? .gray
    RoundedRectangle(cornerRadius: 4)
        .fill(color)
        .frame(width: 20, height: 20)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(isLightColor(name) ? Color.gray.opacity(0.6) : .clear, lineWidth: 1)
        )
}

/// 행운 컬러 이름(한국어/영어)을 SwiftUI Color로 변환. 매칭되지 않으면 nil.
private func colorFromName(_ name: String) -> Color? {
    let n = name.trimmingCharacters(in: .whitespaces).lowercased()
    if n.isEmpty { return nil }
    switch n {
    case "빨강", "빨간색", "레드", "red": return .red
    case "주황", "주황색", "오렌지", "orange": return .orange
    case "노랑", "노란색", "옐로우", "yellow": return .yellow
    case "초록", "녹색", "그린", "green": return .green
    case "파랑", "파란색", "블루", "blue": return .blue
    case "남색", "네이비", "navy": return Color(red: 0, green: 0, blue: 0.5)
    case "보라", "보라색", "퍼플", "purple", "violet": return .purple
    case "분홍", "핑크", "pink": return .pink
    case "갈색", "브라운", "brown": return .brown
    case "흰색", "화이트", "white": return .white
    case "회색", "그레이", "grey", "gray": return .gray
    case "검정", "검은색", "블랙", "black": return .black
    case "금색", "골드", "gold": return Color(red: 1, green: 0.84, blue: 0)
    case "은색", "실버", "silver": return Color(red: 0.75, green: 0.75, blue: 0.75)
    case "베이지", "beige": return Color(red: 0.96, green: 0.96, blue: 0.86)
    case "민트", "mint": return Color(red: 0.6, green: 1, blue: 0.8)
    case "청록", "티얼", "teal": return Color(red: 0, green: 0.5, blue: 0.5)
    case "코랄", "coral": return Color(red: 1, green: 0.5, blue: 0.31)
    case "하늘색", "스카이블루", "물색": return Color(red: 0.53, green: 0.81, blue: 0.98)
    default: return nil
    }
}

// MARK: - 탭 3: 설정

/// 알림 시간 표시 라벨 (분 단위 → 문자열)
private func notificationTimeLabel(minutes: Int) -> String {
    let h = minutes / 60
    let m = minutes % 60
    if h == 12 && m == 0 { return "오후 12시" }
    let hour12 = h == 12 ? 12 : (h % 12)
    let period = h >= 12 ? "오후" : "오전"
    if m == 0 {
        return "\(period) \(hour12)시"
    } else {
        return "\(period) \(hour12)시 \(m)분"
    }
}

private let notificationHourOptions = [7, 8, 9, 10, 11, 12]
private let notificationMinuteOptions = [0, 30]

private func hourLabel(_ h: Int) -> String {
    if h == 12 { return "오후 12시" }
    return h >= 12 ? "오후 \(h % 12)시" : "오전 \(h)시"
}

private func minuteLabel(_ m: Int) -> String {
    m == 0 ? "00분" : "\(m)분"
}

struct SettingsView: View {
    @AppStorage("selectedZodiac") private var selectedZodiacRaw: String = ZodiacSign.aries.rawValue
    @AppStorage("notificationsEnabled") private var notificationsEnabled: Bool = false
    /// 분 단위 저장 (420=7:00, 450=7:30, ... 720=12:00). 구버전 호환: 7~21이면 해당 시 * 60으로 해석
    @AppStorage("notificationMinutes") private var notificationMinutes: Int = 420
    @State private var selectedHour: Int = 7
    @State private var selectedMinute: Int = 0
    @State private var isTimePickerExpanded: Bool = false

    private func minutesFromHourMinute() -> Int {
        selectedHour * 60 + selectedMinute
    }

    private var currentSign: ZodiacSign {
        ZodiacSign(rawValue: selectedZodiacRaw) ?? .aries
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("내 별자리") {
                    Picker("내 별자리", selection: $selectedZodiacRaw) {
                        ForEach(ZodiacSign.allCases) { sign in
                            Text("\(sign.emoji) \(sign.rawValue)")
                                .tag(sign.rawValue)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section("알림") {
                    Toggle(isOn: $notificationsEnabled) {
                        Text("아침 운세 알림 받기")
                    }

                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isTimePickerExpanded.toggle()
                        }
                    } label: {
                        HStack {
                            Text("알림 시간")
                            Spacer()
                            Text(notificationTimeLabel(minutes: minutesFromHourMinute()))
                                .foregroundColor(.blue)
                            Image(systemName: "chevron.up")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.blue.opacity(0.5))
                                .rotationEffect(.degrees(isTimePickerExpanded ? 0 : 180))
                        }
                    }
                    .disabled(!notificationsEnabled)
                    .buttonStyle(.plain)

                    if isTimePickerExpanded {
                        HStack(spacing: 0) {
                            Picker("시", selection: $selectedHour) {
                                ForEach(notificationHourOptions, id: \.self) { h in
                                    Text(hourLabel(h))
                                        .tag(h)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(maxWidth: .infinity)
                            .clipped()

                            Picker("분", selection: $selectedMinute) {
                                ForEach(selectedHour == 12 ? [0] : notificationMinuteOptions, id: \.self) { m in
                                    Text(minuteLabel(m))
                                        .tag(m)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(maxWidth: .infinity)
                            .clipped()
                        }
                        .frame(height: 140)
                        .onChange(of: selectedHour) { newHour in
                            if newHour == 12 { selectedMinute = 0 }
                            notificationMinutes = minutesFromHourMinute()
                        }
                        .onChange(of: selectedMinute) { _ in notificationMinutes = minutesFromHourMinute() }
                    }

                    Text("""
설정한 시간에 오늘의 운세를 알림으로 알려드립니다.
운세는 매일 오전 7시에 업데이트됩니다.
""")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                }

                Section("위젯 설정 가이드") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("홈 화면에 위젯 추가하기")
                            .font(.headline)
                        Text("""
1. 홈 화면을 길게 눌러 편집 모드로 들어갑니다.
2. 좌측 상단의 + 버튼을 누릅니다.
3. '아침 별자리 운세' 위젯을 선택합니다.
4. 원하는 크기를 고르고 홈 화면에 추가합니다.
""")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    }
                }

                Section("정보") {
                    HStack {
                        Text("앱 이름")
                        Spacer()
                        Text("아침 별자리 운세 위젯")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("버전")
                        Spacer()
                        Text("0.1.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("설정")
            .onAppear {
                var mins = notificationMinutes
                if UserDefaults.standard.object(forKey: "notificationMinutes") == nil,
                   let oldHour = UserDefaults.standard.object(forKey: "notificationHour") as? Int,
                   (7...21).contains(oldHour) {
                    mins = oldHour * 60
                    notificationMinutes = mins
                }
                if !(420...720).contains(mins) || mins % 30 != 0 {
                    mins = 420
                    notificationMinutes = mins
                }
                selectedHour = mins / 60
                selectedMinute = mins % 60
                if !notificationHourOptions.contains(selectedHour) {
                    selectedHour = 7
                }
                if !notificationMinuteOptions.contains(selectedMinute) {
                    selectedMinute = 0
                }
            }
        }
    }
}

// MARK: - 공용 상세 뷰

/// 상세 운세 문장 배열 (마침표·공백 기준으로 분리, 각 문장 끝에 마침표 포함)
private func detailSentences(from detail: String) -> [String] {
    let trimmed = detail.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return [] }
    let parts = trimmed.components(separatedBy: CharacterSet(charactersIn: ".。"))
    return parts
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }
        .map { line in line.hasSuffix(".") || line.hasSuffix("!") || line.hasSuffix("?") ? line : line + "." }
}

struct HoroscopeDetailView: View {
    let horoscope: DailyHoroscope

    private var detailLines: [String] {
        detailSentences(from: horoscope.detail)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    Text(horoscope.sign.emoji)
                        .font(.system(size: 48))
                    VStack(alignment: .leading, spacing: 4) {
                        Text(horoscope.sign.rawValue)
                            .font(.title2.bold())
                        Text("오늘의 순위 \(horoscope.rank)위")
                            .font(.headline)
                            .foregroundColor(.blue)
                    }
                }

                Text("한줄평")
                    .font(.headline)
                Text(horoscope.shortMessage)
                    .font(.body)

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("자세한 설명")
                        .font(.headline)
                    if detailLines.isEmpty {
                        Text(horoscope.detail)
                            .font(.body)
                    } else {
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(Array(detailLines.enumerated()), id: \.offset) { _, line in
                                Text(line)
                                    .font(.body)
                            }
                        }
                    }
                }

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("행운 요소")
                        .font(.headline)
                    HStack {
                        VStack(alignment: .leading) {
                            Text("행운 컬러")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            HStack(spacing: 8) {
                                luckyColorSwatch(horoscope.luckyColor)
                                Text(horoscope.luckyColor)
                                    .font(.body)
                                    .foregroundColor(.primary)
                            }
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("행운 아이템")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text(horoscope.luckyItem)
                                .font(.body)
                        }
                    }
                }

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("상세 운세")
                        .font(.headline)
                    scoreRow(for: horoscope, font: .caption)
                }
            }
            .padding()
        }
        .navigationTitle("상세 운세")
        .background(Color.white)
    }
}


#Preview {
    ContentView()
}
