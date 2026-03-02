# 별자리 크롤링 설정 (cron-job.org + GitHub Actions)

## 개요

- **cron-job.org**가 매일 6:30 KST에 GitHub API를 호출 → **repository_dispatch** 트리거
- GitHub Actions가 크롤링 + GPT 번역 후 `data/` 커밋·푸시
- GitHub `schedule` 대신 사용 → **정각 실행** (지연 최소화)

---

## 1. GitHub Secrets 등록

1. 저장소 → **Settings** → **Secrets and variables** → **Actions**
2. **New repository secret** → Name: `OPENAI_API_KEY`, Value: OpenAI API 키
3. 저장

---

## 2. GitHub Personal Access Token (PAT) 생성

cron-job.org가 repository_dispatch를 호출하려면 PAT 필요.

1. GitHub → **Settings** → **Developer settings** → **Personal access tokens**
2. **Tokens (classic)** → **Generate new token (classic)**
3. Note: `acai-bowl-cron`
4. Expiration: 원하는 기간
5. Scope: **repo** 체크
6. **Generate token** → 토큰 복사 (한 번만 표시됨)

---

## 3. cron-job.org 설정

1. https://cron-job.org 가입 (무료)
2. **Create cronjob** 클릭
3. 아래 값 입력:

| 항목 | 값 |
|------|-----|
| **Title** | acai-bowl horoscope |
| **URL** | `https://api.github.com/repos/y222eeeet/acai-bowl/dispatches` |
| **Request method** | `POST` |
| **Schedule** | Every day, 06:30 (또는 Custom → Cron: `30 6 * * *`) |
| **Time zone** | `Asia/Seoul` |

4. **Request headers** 섹션에서 Add header:

| Name | Value |
|------|-------|
| `Authorization` | `Bearer 여기에_PAT_붙여넣기` |
| `Accept` | `application/vnd.github+json` |
| `X-GitHub-Api-Version` | `2022-11-28` |

> Classic PAT도 `Bearer ghp_xxxx` 사용 가능 (최신 GitHub API)

5. **Request body** (Body type: `JSON`):

```json
{"event_type": "daily-crawl"}
```

6. **Create cronjob** 저장

---

## 4. 동작 확인

- **수동 실행**: GitHub → Actions → Horoscope Daily Crawl → **Run workflow**
- **repository_dispatch 테스트** (PAT로 직접 호출):
  ```bash
  curl -X POST \
    -H "Authorization: Bearer YOUR_PAT" \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    https://api.github.com/repos/y222eeeet/acai-bowl/dispatches \
    -d '{"event_type": "daily-crawl"}'
  ```
- **cron-job.org**: 대시보드에서 실행 이력 확인
- **6:30 KST** 실행 후 `data/{날짜}_kr.json` 커밋 여부 확인

---

## 5. 보안 참고

- PAT는 cron-job.org에만 저장. GitHub Secrets에 넣을 필요 없음.
- PAT 유출 시 GitHub에서 즉시 revoke 후 새 토큰 발급.
- `repo` 권한만 부여해 최소 권한 유지.
