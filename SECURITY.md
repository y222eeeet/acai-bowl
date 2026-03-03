# 보안 가이드

이 문서는 acai bowl 프로젝트에서 **절대 커밋하면 안 되는** 민감 정보와 보안 체크리스트를 정리해 두었어요.

---

## 절대 커밋 금지

| 항목 | 설명 | 안전한 관리 방법 |
|------|------|------------------|
| `OPENAI_API_KEY` | OpenAI API 키 (`sk-`로 시작) | 환경변수, GitHub Secrets |
| GitHub PAT | Personal Access Token (`ghp_`로 시작) | cron-job.org 등 서비스에만 저장 |
| `HOROSCOPE_APP_SECRET` | 번역 서버 앱 시크릿 | Info.plist (빌드 시 주입) 또는 xcconfig |
| `.env` 파일 | API 키·비밀번호 포함 가능 | `.gitignore` 등록됨, 로컬만 사용 |
| `*.pem`, `*.key` | 인증서·개인키 | `.gitignore` 등록됨 |

---

## 현재 보안 상태 (검토일: 2026-03)

### 안전하게 처리된 항목

- **OPENAI_API_KEY**: GitHub Actions에서 `secrets.OPENAI_API_KEY` 사용, 코드에 하드코딩 없음
- **크롤러 스크립트**: `os.environ.get("OPENAI_API_KEY")`로 환경변수만 참조
- **서버**: `os.environ.get("OPENAI_API_KEY")`, `HOROSCOPE_APP_SECRET` 환경변수 사용
- **.env**: `.gitignore`로 추적 제외

### 주의할 점

1. **HoroscopeBaseURL**  
   `project.pbxproj`에 `https://raw.githubusercontent.com/y222eeeet/acai-bowl/main/data` 형태로 설정돼 있어요. 공개 저장소 URL이므로 비밀은 아니지만, 레포 주인/포크와 맞는지 확인하세요.

2. **DEVELOPMENT_TEAM**  
   Apple Team ID (`KN5NQM9FL3`)가 `project.pbxproj`에 있어요. 앱스토어 연동 시 필요한 값이라 많은 오픈소스에서 공개돼 있어요. 팀 정책상 숨기려면 `xcconfig`로 분리해 빌드 시 주입하는 방식으로 변경할 수 있어요.

3. **cron-job.org PAT**  
   `HOROSCOPE_SETUP.md`에서 `Bearer ghp_여기에PAT붙여넣기` 같은 예시만 사용하고 있어요. **절대 실제 토큰을 문서에 붙여넣지 마세요.** cron-job.org 대시보드에만 입력하세요.

---

## 새 기능 추가 시 체크리스트

- [ ] API 키·토큰을 코드·설정 파일에 직접 적지 않았는지 확인
- [ ] 필요한 값은 환경변수 또는 GitHub Secrets로만 관리
- [ ] 문서에 `sk-...`, `ghp_...` 등 실제 값이 들어가 있지 않은지 확인
- [ ] `.gitignore`에 새로 만든 민감 파일 패턴 추가

---

## 유출 의심 시 대응

1. **OpenAI API 키**: [OpenAI API Keys](https://platform.openai.com/api-keys)에서 즉시 revoke 후 새 키 발급
2. **GitHub PAT**: GitHub → Settings → Developer settings → Revoke 후 새 토큰 발급
3. **HOROSCOPE_APP_SECRET**: 서버·앱 양쪽에서 새 값으로 변경 후 재배포
