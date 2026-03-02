#!/usr/bin/env python3
"""
운세 번역 프록시 API (배포용).
- 앱에서 한국어 데이터가 없을 때, 일본어 페이로드를 이 서버로 보내면
  서버가 OpenAI API로 번역·한줄평 생성 후 한국어 페이로드를 반환합니다.
- OpenAI API 키는 서버 환경변수(OPENAI_API_KEY)에만 두며, 앱에는 절대 포함하지 않습니다.

보안:
- OPENAI_API_KEY: 서버 환경변수만 사용 (코드/앱에 노출 금지)
- HOROSCOPE_APP_SECRET (선택): 설정 시 X-App-Secret 헤더 검증
- Rate limit: IP당 분당 요청 제한
- HTTPS 배포 권장 (Cloud Run, Railway 등은 기본 HTTPS)

실행 (배포 전 로컬 테스트, 프로젝트 루트에서):
  export OPENAI_API_KEY=sk-...
  pip install -r server/requirements.txt
  uvicorn server.main:app --host 0.0.0.0 --port 8080
"""

import os
import sys
import time
from collections import defaultdict
from typing import Any, Dict, List, Optional

# 프로젝트 scripts 폴더를 path에 추가해 크롤러·번역 규칙 import
_REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
_SCRIPTS = os.path.join(_REPO_ROOT, "scripts")
if _SCRIPTS not in sys.path:
    sys.path.insert(0, _SCRIPTS)

from fastapi import FastAPI, Header, Request, HTTPException
from fastapi.responses import JSONResponse
from pydantic import BaseModel

# 크롤러의 GPT 번역·후처리 사용 (API 키는 크롤러가 os.environ에서 읽음)
import horoscope_crawler as crawler

app = FastAPI(
    title="Horoscope Translate API",
    description="일본어 운세 페이로드를 한국어로 번역합니다. OpenAI API 키는 서버에만 있습니다.",
    version="1.0",
)

# --- Rate limiting (인메모리, 단일 인스턴스 기준) ---
RATE_LIMIT_REQUESTS = 20
RATE_LIMIT_WINDOW_SEC = 60
_rate: Dict[str, List[float]] = defaultdict(list)


def _get_client_ip(request: Request) -> str:
    return request.client.host if request.client else "unknown"


def _check_rate_limit(ip: str) -> None:
    now = time.time()
    window_start = now - RATE_LIMIT_WINDOW_SEC
    _rate[ip] = [t for t in _rate[ip] if t > window_start]
    if len(_rate[ip]) >= RATE_LIMIT_REQUESTS:
        raise HTTPException(status_code=429, detail="Too many requests. Try again later.")
    _rate[ip].append(now)


def _check_app_secret(x_app_secret: Optional[str] = None) -> None:
    secret = os.environ.get("HOROSCOPE_APP_SECRET")
    if not secret:
        return
    if not x_app_secret or x_app_secret.strip() != secret:
        raise HTTPException(status_code=401, detail="Invalid or missing app secret.")


# --- Request/Response (앱 _jp.json / _kr.json과 동일 구조) ---
class Item(BaseModel):
    date: str
    sign: str
    rank: int
    shortMessage: str
    detail: str
    luckyColor: str
    luckyItem: str
    moneyScore: int = 0
    loveScore: int = 0
    workScore: int = 0
    healthScore: int = 0


class TranslateRequest(BaseModel):
    date: str
    items: List[Item]


class TranslateResponse(BaseModel):
    date: str
    items: List[Item]


def _item_to_horoscope(item: Item) -> crawler.HoroscopeItem:
    return crawler.HoroscopeItem(
        date=item.date,
        sign=item.sign,
        rank=item.rank,
        shortMessage=item.shortMessage,
        detail=item.detail,
        luckyColor=item.luckyColor or "",
        luckyItem=item.luckyItem or "",
        moneyScore=item.moneyScore,
        loveScore=item.loveScore,
        workScore=item.workScore,
        healthScore=item.healthScore,
    )


def _horoscope_to_item(h: crawler.HoroscopeItem) -> Item:
    return Item(
        date=h.date,
        sign=h.sign,
        rank=h.rank,
        shortMessage=h.shortMessage,
        detail=h.detail,
        luckyColor=h.luckyColor or "",
        luckyItem=h.luckyItem or "",
        moneyScore=h.moneyScore,
        loveScore=h.loveScore,
        workScore=h.workScore,
        healthScore=h.healthScore,
    )


@app.post("/v1/translate", response_model=TranslateResponse)
async def translate(
    body: TranslateRequest,
    request: Request,
    x_app_secret: Optional[str] = Header(None, alias="X-App-Secret"),
) -> TranslateResponse:
    """
    일본어 운세 페이로드를 받아 한국어(번역+한줄평)로 변환해 반환합니다.
    OpenAI API 키는 서버 환경변수 OPENAI_API_KEY에만 있어야 합니다.
    """
    if not os.environ.get("OPENAI_API_KEY"):
        raise HTTPException(
            status_code=503,
            detail="Translation service is not configured (missing OPENAI_API_KEY).",
        )
    _check_rate_limit(_get_client_ip(request))
    _check_app_secret(x_app_secret)

    items_ja = [_item_to_horoscope(i) for i in body.items]
    try:
        items_ko = crawler.translate_items_to_korean(items_ja)
    except Exception as e:
        raise HTTPException(status_code=502, detail="Translation failed.") from e

    return TranslateResponse(
        date=body.date,
        items=[_horoscope_to_item(h) for h in items_ko],
    )


@app.get("/health")
async def health() -> Dict[str, str]:
    """배포 환경에서 서비스 생존 확인용. API 키는 반환하지 않습니다."""
    return {"status": "ok"}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=int(os.environ.get("PORT", "8080")))
