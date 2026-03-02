# 별자리 크롤링 GitHub Actions 설정

## 1. OPENAI_API_KEY 시크릿 등록

1. GitHub 저장소 → **Settings** → **Secrets and variables** → **Actions**
2. **New repository secret** 클릭
3. Name: `OPENAI_API_KEY`
4. Value: OpenAI API 키 (예: `sk-...`)
5. **Add secret** 저장

> ⚠️ API 키는 절대 코드에 커밋하지 마세요. GitHub Secrets만 사용합니다.

## 2. 동작 방식

- **스케줄**: 매일 오전 6:30 (한국 시간)
- **수동 실행**: Actions 탭 → Horoscope Daily Crawl → Run workflow
- **결과**: `data/{날짜}_jp.json`, `data/{날짜}_kr.json` 자동 생성 후 커밋·푸시

## 3. 앱 연동

- `data/` 폴더가 Xcode 프로젝트 리소스로 포함되어 있으면 빌드 시 최신 운세 데이터가 앱에 포함됩니다.
- GitHub Actions가 매일 새 데이터를 커밋하므로, 앱을 다시 빌드하면 최신 운세를 사용할 수 있습니다.
