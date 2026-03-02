//
//  HoroscopeTranslationStore.swift
//  acai bowl
//
//  운세 데이터를 불러와 화면에 공급하는 Store.
//  한국어 번역본(_kr.json)만 로드합니다. (GPT는 크롤러에서 번역·한줄평 생성 후 _kr.json으로 저장)
//

import Foundation
import SwiftUI
import Combine

// MARK: - Store

/// 운세 데이터를 불러와 화면에 공급하는 Store.
/// 한국어(_kr.json)만 로드. 번들 또는 HoroscopeBaseURL에서 가져옵니다.
@MainActor
final class HoroscopeTranslationStore: ObservableObject {

    @Published private(set) var payload: HoroscopeDayPayload
    @Published private(set) var isLoading = false
    @Published private(set) var loadError: String?

    private let dummyPayload: HoroscopeDayPayload

    init(dummyPayload: HoroscopeDayPayload = DummyHoroscopeRepository.shared.todayPayload()) {
        self.dummyPayload = dummyPayload
        self.payload = dummyPayload
    }

    /// 한국어 번역본(_kr.json) 로드. KST 기준. 6:30 이전이면 어제 데이터로 폴백.
    func load() async {
        guard !isLoading else { return }
        isLoading = true
        loadError = nil
        defer { isLoading = false }

        do {
            let kr = try await HoroscopeAPI.shared.fetchTodayKorean()
            payload = kr
            return
        } catch {}

        if !HoroscopeAPI.isPastCrawlTimeKST {
            do {
                let kr = try await HoroscopeAPI.shared.fetchKorean(for: HoroscopeAPI.yesterdayDateKST)
                payload = kr
                return
            } catch {}
        }

        do {
            let jp = try await HoroscopeAPI.shared.fetchTodayJapanese()
            let kr = try await HoroscopeAPI.shared.fetchKoreanViaTranslate(japanesePayload: jp)
            payload = kr
        } catch {
            loadError = error.localizedDescription
            payload = dummyPayload
        }
    }
}
