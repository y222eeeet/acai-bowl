# 위젯 설정 가이드

## 1. Widget Extension 타깃 추가

1. Xcode에서 **File** → **New** → **Target**
2. **Application Extension** → **Widget Extension** 선택 → **Next**
3. **Product Name**: `acai bowl Widget`
4. **Include Live Activity**, **Include Configuration App Intent** **체크 해제**
5. **Finish** → Activate scheme 선택

## 2. 기존 위젯 코드로 교체

1. Xcode가 생성한 `acai bowl Widget` 폴더 내 기본 `.swift` 파일을 **삭제**
2. 프로젝트 네비게이터에서 `acai bowl Widget` 폴더 우클릭 → **Add Files to "acai bowl"...**
3. `acai bowl Widget/HoroscopeWidget.swift` 선택 → **Add**
4. "Copy items if needed" 체크 해제, "Add to targets"에서 **acai bowl Widget**만 체크

또는: 생성된 `*Widget.swift` 파일을 열고, `HoroscopeWidget.swift` 내용 전체 복사해 덮어쓰기

## 3. App Group 설정

### 메인 앱 (acai bowl)
1. Project → **acai bowl** 타깃 → **Signing & Capabilities**
2. **+ Capability** → **App Groups** 추가
3. `group.jiwooseo.acai-bowl` 추가 (또는 + 버튼으로 생성)
4. **Build Settings** → "Code Signing Entitlements" 검색 → `acai bowl/acai bowl.entitlements` 지정 (선택)

### 위젯 (acai bowl Widget)
1. **acai bowl Widget** 타깃 → **Signing & Capabilities**
2. **+ Capability** → **App Groups**
3. 동일하게 `group.jiwooseo.acai-bowl` 추가

## 4. 빌드 및 테스트

1. 메인 앱을 실행해 오늘 운세 로드
2. 홈 화면 길게 누르기 → **+** → 위젯 찾기 → **오늘의 운세** (systemSmall) 추가
3. 별자리 이모지 + 순위 + 한줄평이 표시되는지 확인
