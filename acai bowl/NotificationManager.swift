//
//  NotificationManager.swift
//  acai bowl
//
//  알림 시간에 당일 운세(순위, 한줄평)를 전달.
//

import Foundation
import UserNotifications

enum NotificationManager {
    static let horoscopeIdentifier = "horoscope-daily"

    /// 순위에 따른 알림 제목
    static func title(for rank: Int) -> String {
        switch rank {
        case 1...3: return "🚀 오늘 운세 상위권!"
        case 4...8: return "🌤 오늘은 무난한 하루"
        default: return "🌥 오늘은 방향을 잡는 하루"
        }
    }

    /// 알림 본문: (별자리) (순위). (한줄평)
    static func body(sign: String, rank: Int, shortMessage: String) -> String {
        "\(sign) \(rank)위. \(shortMessage)"
    }

    /// 권한 요청
    static func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            return try await center.requestAuthorization(options: [.alert, .sound])
        } catch {
            return false
        }
    }

    /// 기존 알림 취소 후 다음 알림 예약. notificationsEnabled, notificationMinutes는 UserDefaults에서 직접 읽음.
    /// payload의 날짜가 알림 예정일(KST)과 같을 때만 horoscope 내용 사용.
    static func scheduleIfNeeded(
        horoscope: (sign: String, rank: Int, shortMessage: String)?,
        payloadDate: Date?
    ) {
        let defaults = UserDefaults.standard
        guard defaults.bool(forKey: "notificationsEnabled") else {
            cancelScheduled()
            return
        }

        Task { @MainActor in
            let granted = await requestPermission()
            guard granted else { return }
            await _schedule(horoscope: horoscope, payloadDate: payloadDate)
        }
    }

    @MainActor
    private static func _schedule(
        horoscope: (sign: String, rank: Int, shortMessage: String)?,
        payloadDate: Date?
    ) async {
        let defaults = UserDefaults.standard
        guard defaults.bool(forKey: "notificationsEnabled") else {
            cancelScheduled()
            return
        }

        var mins = defaults.integer(forKey: "notificationMinutes")
        if mins < 420 || mins > 720 { mins = 420 }

        let hour = mins / 60
        let minute = mins % 60

        let tz = TimeZone(identifier: "Asia/Seoul") ?? .current
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = tz

        var dateComponents = DateComponents()
        dateComponents.timeZone = tz
        dateComponents.hour = hour
        dateComponents.minute = minute

        let content = UNMutableNotificationContent()
        content.sound = .default
        content.categoryIdentifier = "HOROSCOPE"

        let useHoroscope = horoscope != nil
            && payloadDate != nil
            && cal.isDateInToday(payloadDate!)
        if let h = horoscope, useHoroscope {
            content.title = title(for: h.rank)
            content.body = body(sign: h.sign, rank: h.rank, shortMessage: h.shortMessage)
        } else {
            content.title = "🌤 오늘의 운세"
            content.body = "앱을 열어 오늘 운세를 확인해 보세요."
        }

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: true
        )
        let request = UNNotificationRequest(identifier: horoscopeIdentifier, content: content, trigger: trigger)

        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [horoscopeIdentifier])
        do {
            try await center.add(request)
        } catch {}
    }

    static func cancelScheduled() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [horoscopeIdentifier])
    }
}
