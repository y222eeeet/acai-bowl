# 운세 번역 API (배포용)

앱에서 **한국어 데이터가 없을 때** 일본어 페이로드를 이 서버로 보내면, 서버가 **OpenAI API**로 번역·한줄평을 생성해 한국어 페이로드를 반환합니다.

## 보안 (API 키 노출 방지)

- **OpenAI API 키는 서버 환경변수에만** 두고, 앱 바이너리·소스·Info.plist에는 **절대 넣지 마세요**.
- 앱은 이 서버 URL만 호출하며, 서버가 내부적으로 OpenAI를 호출합니다.
- **HTTPS**로만 배포하세요 (Cloud Run, Railway, Fly.io 등은 기본 HTTPS).
- (선택) `HOROSCOPE_APP_SECRET`: 서버에 설정하면 앱이 `X-App-Secret` 헤더로 같은 값을 보내야 합니다. 앱에는 이 시크릿만 Info에 넣고, **OpenAI 키와는 다른 값**입니다. 유출 시 서버에서 값만 변경해 재배포하면 됩니다.

## 환경변수

| 변수 | 필수 | 설명 |
|------|------|------|
| `OPENAI_API_KEY` | 예 | OpenAI API 키. **서버에만** 설정. |
| `HOROSCOPE_APP_SECRET` | 아니오 | 설정 시 `X-App-Secret` 헤더 검증. 앱 Info.plist `HoroscopeAppSecret`와 동일하게. |
| `PORT` | 아니오 | 서버 포트 (기본 8080). |

## 로컬 실행

프로젝트 루트에서:

```bash
export OPENAI_API_KEY=sk-...
pip install -r server/requirements.txt
uvicorn server.main:app --host 0.0.0.0 --port 8080
```

## 배포 예시 (Google Cloud Run)

```bash
cd "acai bowl"
gcloud run deploy horoscope-translate \
  --source . \
  --set-env-vars OPENAI_API_KEY=sk-xxx \
  --allow-unauthenticated
```

- `HOROSCOPE_APP_SECRET` 사용 시: `--set-env-vars "OPENAI_API_KEY=sk-xxx,HOROSCOPE_APP_SECRET=your-random-secret"`  
- 앱 Info.plist에 `HoroscopeTranslateURL` = Cloud Run URL, `HoroscopeAppSecret` = 위와 같은 시크릿.

## Rate limit

- IP당 **분당 20회** 요청 제한 (인메모리). 필요 시 Redis 등으로 분산 제한 가능.

## 앱 설정 (Xcode)

- **HoroscopeTranslateURL**: 번역 API 기본 URL (예: `https://horoscope-translate-xxx.run.app`). **HTTPS만** 사용.
- **HoroscopeAppSecret**: (선택) 서버 `HOROSCOPE_APP_SECRET`와 동일한 값. 없으면 서버에서 해당 검증 비활성화.
