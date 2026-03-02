//
//  WidgetDataManager.swift
//  acai bowl
//
//  위젯용 데이터를 App Group에 저장. 앱에서 호출.
//

import Foundation
import WidgetKit

enum WidgetDataManager {
    static let appGroupID = "group.jiwooseo.acai-bowl"

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    /// 위젯용 데이터 저장. load() 직후 또는 selectedZodiac 변경 시 호출.
    static func update(selectedZodiac: String, zodiacEmoji: String, rank: Int, shortMessage: String, detail: String) {
        defaults?.set(selectedZodiac, forKey: "widgetSelectedZodiac")
        defaults?.set(zodiacEmoji, forKey: "widgetZodiacEmoji")
        defaults?.set(rank, forKey: "widgetRank")
        defaults?.set(shortMessage, forKey: "widgetShortMessage")
        defaults?.set(detail, forKey: "widgetDetail")
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// 별자리만 저장 (번들 폴백용). payload 없을 때 호출.
    static func updateSelectedZodiacOnly(_ selectedZodiac: String) {
        defaults?.set(selectedZodiac, forKey: "widgetSelectedZodiac")
        WidgetCenter.shared.reloadAllTimelines()
    }
}
