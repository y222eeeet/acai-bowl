//
//  acai_bowl_Widget.swift
//  acai bowl Widget
//
//  systemSmall: 별자리 이모지 + 오늘 순위 + 한줄평
//

import WidgetKit
import SwiftUI

struct HoroscopeWidgetData {
    let zodiacEmoji: String
    let rank: Int
    let shortMessage: String
    let detail: String

    static let empty = HoroscopeWidgetData(
        zodiacEmoji: "⭐",
        rank: 0,
        shortMessage: "앱을 열어 오늘 운세를 확인해 보세요",
        detail: ""
    )

    static func load() -> HoroscopeWidgetData {
        if let fromAppGroup = loadFromAppGroup() { return fromAppGroup }
        if let fromBundle = loadFromAppBundle() { return fromBundle }
        return .empty
    }

    private static func loadFromAppGroup() -> HoroscopeWidgetData? {
        guard let defaults = UserDefaults(suiteName: "group.jiwooseo.acai-bowl"),
              let emoji = defaults.string(forKey: "widgetZodiacEmoji"),
              let message = defaults.string(forKey: "widgetShortMessage") else {
            return nil
        }
        let rank = defaults.integer(forKey: "widgetRank")
        guard rank > 0 else { return nil }
        let detail = defaults.string(forKey: "widgetDetail") ?? ""
        return HoroscopeWidgetData(zodiacEmoji: emoji, rank: rank, shortMessage: message, detail: detail)
    }

    private static func loadFromAppBundle() -> HoroscopeWidgetData? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        let dateStr = formatter.string(from: Date())
        let fileName = "\(dateStr)_kr.json"

        let appBundleURL = Bundle.main.bundleURL
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let dataURL = appBundleURL
            .appendingPathComponent("data")
            .appendingPathComponent(fileName)
        guard let jsonData = try? Data(contentsOf: dataURL),
              let payload = try? JSONDecoder().decode(WidgetPayload.self, from: jsonData) else {
            return nil
        }
        let selectedZodiac = UserDefaults(suiteName: "group.jiwooseo.acai-bowl")?.string(forKey: "widgetSelectedZodiac") ?? "양자리"
        guard let item = payload.items.first(where: { $0.sign == selectedZodiac }) else {
            return nil
        }
        let emoji = signToEmoji(selectedZodiac)
        return HoroscopeWidgetData(zodiacEmoji: emoji, rank: item.rank, shortMessage: item.shortMessage, detail: item.detail)
    }

    private static func signToEmoji(_ sign: String) -> String {
        switch sign {
        case "양자리": return "🐏"
        case "황소자리": return "🐂"
        case "쌍둥이자리": return "👯"
        case "게자리": return "🦀"
        case "사자자리": return "🦁"
        case "처녀자리": return "🌾"
        case "천칭자리": return "⚖️"
        case "전갈자리": return "🦂"
        case "사수자리": return "🏹"
        case "염소자리": return "🐐"
        case "물병자리": return "🏺"
        case "물고기자리": return "🐟"
        default: return "⭐"
        }
    }
}

private struct WidgetPayload: Codable {
    let items: [WidgetPayloadItem]
}

private struct WidgetPayloadItem: Codable {
    let sign: String
    let rank: Int
    let shortMessage: String
    let detail: String
}

struct HoroscopeWidgetEntry: TimelineEntry {
    let date: Date
    let data: HoroscopeWidgetData
}

struct HoroscopeProvider: TimelineProvider {
    func placeholder(in context: Context) -> HoroscopeWidgetEntry {
        HoroscopeWidgetEntry(date: Date(), data: HoroscopeWidgetData.empty)
    }

    func getSnapshot(in context: Context, completion: @escaping (HoroscopeWidgetEntry) -> Void) {
        let data = HoroscopeWidgetData.load()
        completion(HoroscopeWidgetEntry(date: Date(), data: data))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HoroscopeWidgetEntry>) -> Void) {
        let data = HoroscopeWidgetData.load()
        let entry = HoroscopeWidgetEntry(date: Date(), data: data)
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

struct HoroscopeWidgetEntryView: View {
    var entry: HoroscopeProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(data: entry.data)
        case .systemMedium:
            MediumWidgetView(data: entry.data)
        default:
            SmallWidgetView(data: entry.data)
        }
    }
}

struct SmallWidgetView: View {
    let data: HoroscopeWidgetData

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Text(data.zodiacEmoji)
                    .font(.system(size: 32))
                if data.rank > 0 {
                    Text("\(data.rank)위")
                        .font(.subheadline.bold())
                        .foregroundColor(.blue)
                }
            }
            Text(data.shortMessage)
                .font(.footnote)
                .lineLimit(2)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding()
    }
}

/// 상세 문장 분리 (마침표 기준, 각 문장 끝에 마침표 포함)
private func detailLines(from detail: String) -> [String] {
    let trimmed = detail.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return [] }
    let parts = trimmed.components(separatedBy: CharacterSet(charactersIn: ".。"))
    return parts
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }
        .map { line in line.hasSuffix(".") || line.hasSuffix("!") || line.hasSuffix("?") ? line : line + "." }
}

struct MediumWidgetView: View {
    let data: HoroscopeWidgetData

    private var lines: [String] {
        detailLines(from: data.detail)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(data.zodiacEmoji)
                    .font(.system(size: 36))
                if data.rank > 0 {
                    Text("\(data.rank)위")
                        .font(.headline)
                        .foregroundColor(.blue)
                }
                Spacer()
            }
            Text(data.shortMessage)
                .font(.subheadline.bold())
                .foregroundColor(.primary)
            if !lines.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(lines.prefix(4).enumerated()), id: \.offset) { _, line in
                        Text(line)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
            } else if !data.detail.isEmpty {
                Text(data.detail)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(4)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding()
    }
}

struct acai_bowl_Widget: Widget {
    let kind: String = "HoroscopeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HoroscopeProvider()) { (entry: HoroscopeWidgetEntry) in
            HoroscopeWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("오늘의 운세")
        .description("내 별자리의 오늘 순위와 한줄평을 확인하세요.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    acai_bowl_Widget()
} timeline: {
    HoroscopeWidgetEntry(date: Date(), data: HoroscopeWidgetData(zodiacEmoji: "🦁", rank: 5, shortMessage: "승리의 기회를 잡을 수 있어요", detail: "승부 운이 상승 중이에요. 예상치 못한 승리를 얻을 가능성이 높답니다."))
}
