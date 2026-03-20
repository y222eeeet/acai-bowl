#!/usr/bin/env python3
"""
TV 아사히 '굿모닝' 별자리 운세 페이지를 크롤링해서
iOS 앱에서 사용하는 JSON 포맷으로 저장하는 스크립트.

번역은 GPT만 사용. (deep-translator·translation_rules 제거)

저장 로직:
  - 항상 원본(일본어)을 {날짜}_jp.json 으로 저장.
  - OPENAI_API_KEY가 있으면 GPT로 12건 번역 후 {날짜}_kr.json 저장.
  - GPT 없으면 _kr.json 미생성 (번역은 GPT만 사용).
  - --no-translate 이면 _jp.json 만 저장.

앱 연동:
  - 앱은 한국어(_kr.json)만 로드. (Apple 번역 제거, GPT는 크롤러에서만 사용)
  - data 폴더를 Xcode 프로젝트에 리소스로 넣어 두면 빌드 시 번들에 포함되어 오프라인에서도 표시 가능.
  - 또는 data 를 호스팅하는 URL을 앱 타깃 Info에 "HoroscopeBaseURL" 로 추가.

사용 방법:
    export OPENAI_API_KEY=sk-...
    pip install requests beautifulsoup4 openai
    python3 scripts/horoscope_crawler.py --output data

생성 파일:
  - data/2026-03-01_jp.json  … 원본(일본어): 순위, 일본어 원문, 상세운 점수
  - data/2026-03-01_kr.json  … 번역본(한국어): 동일 구조, 문구만 한국어
"""

import argparse
import dataclasses
import datetime as dt
import json
import os
import re
import sys
import time
from typing import List, Optional

# 같은 scripts/ 폴더의 translation_rules 모듈을 로드하기 위함
_SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
if _SCRIPT_DIR not in sys.path:
    sys.path.insert(0, _SCRIPT_DIR)

import requests
from bs4 import BeautifulSoup, NavigableString

def _has_gpt() -> bool:
    return bool(os.environ.get("OPENAI_API_KEY"))

try:
    from openai import OpenAI
    _openai_client = OpenAI() if _has_gpt() else None
    HAS_GPT = _has_gpt() and _openai_client is not None
except Exception:
    _openai_client = None
    HAS_GPT = False

TV_ASAHI_URL = "https://www.tv-asahi.co.jp/goodmorning/uranai/"


@dataclasses.dataclass
class HoroscopeItem:
    date: str
    sign: str           # 예: "양자리"
    rank: int           # 1 ~ 12
    shortMessage: str
    detail: str
    luckyColor: str
    luckyItem: str
    # 각 영역별 운세 강도 (1~5) - 이미지 개수 기준
    moneyScore: int
    loveScore: int
    workScore: int
    healthScore: int


def fetch_html() -> str:
    resp = requests.get(TV_ASAHI_URL, timeout=10)
    # TV 아사히 페이지는 Shift-JIS 기반일 수 있으므로 인코딩을 강제로 맞춰줌
    resp.encoding = resp.apparent_encoding or "shift_jis"
    resp.raise_for_status()
    return resp.text


def parse_horoscopes(html: str, target_date: dt.date) -> List[HoroscopeItem]:
    """
    HTML을 파싱해서 12개 별자리 운세를 추출한다.

    구조(2026-03-01 기준):
      - 상단 랭킹 박스: <ul class="rank-box">
          <li><a data-label="ohitsuji" href="#ohitsuji">...</a></li>
          ...
      - 각 별자리 상세: <div class="seiza-box" id="ohitsuji"> ... </div>
          <div class="read-area">
            <p class="read">...한 줄/요약...</p>
            <span class="lucky-color-txt">...</span><font>실제 색상</font><br>
            <span class="key-txt">...</span><font>행운의 열쇠</font>
          </div>
    """
    soup = BeautifulSoup(html, "html.parser")

    items: List[HoroscopeItem] = []

    # 순위 정보: rank-box 안의 li 순서가 곧 1~12위
    rank_links = soup.select("ul.rank-box li a[data-label]")
    if not rank_links:
        print("[WARN] ul.rank-box li a[data-label] 셀렉터로 아무 것도 찾지 못했습니다.")
        return items

    # data-label(로마자) -> 우리 앱에서 쓰는 한글 이름 매핑
    sign_label_map = {
        "ohitsuji": "양자리",
        "ousi": "황소자리",
        "futago": "쌍둥이자리",
        "kani": "게자리",
        "sisi": "사자자리",
        "otome": "처녀자리",
        "tenbin": "천칭자리",
        "sasori": "전갈자리",
        "ite": "사수자리",
        "yagi": "염소자리",
        "mizugame": "물병자리",
        "uo": "물고기자리",
    }

    for rank, link in enumerate(rank_links, start=1):
        label = link.get("data-label")
        if not label:
            continue

        seiza_box = soup.select_one(f"div.seiza-box#{label}")
        if not seiza_box:
            # id 가 data-label 과 다를 경우를 대비해 href 기준으로도 시도
            href = link.get("href", "")
            if href.startswith("#"):
                seiza_box = soup.select_one(f"div.seiza-box{href}")
        if not seiza_box:
            print(f"[WARN] seiza-box for label '{label}' not found")
            continue

        read_area = seiza_box.select_one("div.read-area")
        if not read_area:
            print(f"[WARN] read-area not found for label '{label}'")
            continue

        # 한 줄/요약
        p_read = read_area.select_one("p.read")
        short_msg = p_read.get_text(strip=True) if p_read else ""

        # lucky color: <span class="lucky-color-txt">ラッキーカラー</span>：緑 (또는 <font> 중첩)
        lucky_color_span = read_area.select_one("span.lucky-color-txt")
        lucky_color = ""
        if lucky_color_span is not None:
            color_font = lucky_color_span.find_next("font")
            if color_font is not None:
                lucky_color = color_font.get_text(strip=True)
            else:
                # TV 아사히 실제 구조: span 다음에 텍스트 "：緑" (font 없음)
                next_sib = lucky_color_span.next_sibling
                if next_sib is not None and isinstance(next_sib, NavigableString):
                    lucky_color = str(next_sib).strip()
            if lucky_color.startswith(":") or lucky_color.startswith("："):
                lucky_color = lucky_color.lstrip(":：").strip()

        # lucky key/item: <span class="key-txt">幸運のカギ</span>：メガネケース (또는 <font> 중첩)
        key_span = read_area.select_one("span.key-txt")
        lucky_item = ""
        if key_span is not None:
            key_font = key_span.find_next("font")
            if key_font is not None:
                lucky_item = key_font.get_text(strip=True)
            else:
                next_sib = key_span.next_sibling
                if next_sib is not None and isinstance(next_sib, NavigableString):
                    lucky_item = str(next_sib).strip()
            if lucky_item.startswith(":") or lucky_item.startswith("："):
                lucky_item = lucky_item.lstrip(":：").strip()

        # 상세 설명은 일단 read 내용을 그대로 사용(필요하면 추가 텍스트를 더 붙여도 됨)
        detail = short_msg

        # number-one-box 안의 아이콘 개수로 영역별 운세 스코어 추출
        number_one = seiza_box.select_one("div.number-one-box")
        def count_icons(li_selector: str, img_selector: str) -> int:
            if not number_one:
                return 0
            imgs = number_one.select(f"{li_selector} {img_selector}")
            cnt = len(imgs)
            # 1~5 범위로 클램프
            if cnt <= 0:
                return 0
            return max(1, min(cnt, 5))

        money_score = count_icons("li.lucky-money", "p.lucky-box img.icon-money")
        love_score = count_icons("li.lucky-love", "p.lucky-box img.icon-love")
        work_score = count_icons("li.lucky-work", "p.lucky-box img.icon-work")
        health_score = count_icons("li.lucky-health", "p.lucky-box img.icon-health")

        sign_ko = sign_label_map.get(label, label)

        items.append(
            HoroscopeItem(
                date=target_date.isoformat(),
                sign=sign_ko,
                rank=rank,
                shortMessage=short_msg,
                detail=detail,
                luckyColor=lucky_color,
                luckyItem=lucky_item,
                moneyScore=money_score,
                loveScore=love_score,
                workScore=work_score,
                healthScore=health_score,
            )
        )

    # 안전하게 rank 정렬
    items.sort(key=lambda x: x.rank)

    return items


def to_payload(date: dt.date, items: List[HoroscopeItem]) -> dict:
    return {
        "date": date.isoformat(),
        "items": [dataclasses.asdict(i) for i in items],
    }


def to_payload(date: dt.date, items: List[HoroscopeItem]) -> dict:
    return {
        "date": date.isoformat(),
        "items": [dataclasses.asdict(i) for i in items],
    }


def _gpt_translate_one_item(item: HoroscopeItem) -> Optional[HoroscopeItem]:
    """
    GPT로 한 건의 운세를 일본어→한국어 번역하고, 한줄평(shortMessage) 20자 내외 생성.
    반환: 한국어로 채운 HoroscopeItem. 실패 시 None.
    """
    if not HAS_GPT or not _openai_client:
        return None
    prompt = """다음은 일본어 별자리 운세 한 건입니다. 한국어로 번역해 주세요.

[필수] 한자(漢字) 완전 금지
- 출력은 반드시 순한글만. 한자(漢字)가 한 글자라도 포함되면 안 됨.
- 일본어 한자는 모두 한국어로 풀어쓰기: 充実→충실, 恵まれる→혜택받다, 偏る→치우치다, 迎える→맞이하다 등.
- 한자+한글 혼용(充실, 恵まれ, 偏해, 迎 할) 절대 금지. 전부 한글로.

[문체] 반드시 해요체만. 반말 절대 금지.
- X(금지): 참가해, 있어, 좋아, 올 거야, 하자, 응해줘, 찾아와, 레벨이야
- O(필수): 참가해요, 있어요, 좋아요, 올 거예요, 해요, 응해줘요, 찾아와요, 레벨이에요
모든 문장은 ~해요/~예요/~이에요로 끝내기. 합니다/됩니다 금지.

[한줄평] 상세 내용을 반영한 한 문장, 20자 내외, ~해요/~예요/~이에요로 끝내기.

아래 JSON 형식으로만 응답:
{
  "detail": "번역된 상세 운세 전체 (한국어, 문장 구분은 마침표+공백)",
  "shortMessage": "한줄평 한 문장",
  "luckyColor": "행운의 색 번역",
  "luckyItem": "행운의 아이템 번역"
}

일본어 원문:
- 상세(detail): %s
- 행운의 색(luckyColor): %s
- 행운의 아이템(luckyItem): %s
"""
    try:
        resp = _openai_client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[{"role": "user", "content": prompt % (item.detail, item.luckyColor or "なし", item.luckyItem or "なし")}],
            response_format={"type": "json_object"},
        )
        content = resp.choices[0].message.content
        if not content:
            return None
        data = json.loads(content)
        detail = (data.get("detail") or "").strip()
        short_msg = (data.get("shortMessage") or "").strip()
        lucky_color = (data.get("luckyColor") or "").strip()
        lucky_item = (data.get("luckyItem") or "").strip()
        if not detail:
            return None
        detail = _ensure_period_at_end(_normalize_space_after_period(detail))
        short_msg = _short_message_20(short_msg) or "좋은 하루 되세요."
        lucky_color = _normalize_lucky(lucky_color)
        lucky_item = _normalize_lucky(lucky_item)
        return HoroscopeItem(
            date=item.date,
            sign=item.sign,
            rank=item.rank,
            shortMessage=short_msg,
            detail=detail,
            luckyColor=lucky_color,
            luckyItem=lucky_item,
            moneyScore=item.moneyScore,
            loveScore=item.loveScore,
            workScore=item.workScore,
            healthScore=item.healthScore,
        )
    except Exception as e:
        print(f"[WARN] GPT 번역 실패 ({item.sign}): {e}")
        return None


# 배치용 짧은 지시문
_BATCH_PROMPT_PREFIX = """12개 일본어 별자리 운세를 한국어로 번역.

[필수] 한자(漢字) 완전 금지: 출력은 순한글만. 한자가 한 글자도 있으면 안 됨. 일본어 한자는 전부 한글로 풀어쓰기 (充実→충실, 恵まれる→혜택받다, 偏る→치우치다, 迎える→맞이하다 등). 한자+한글 혼용 절대 금지.

[문체] 반드시 해요체만. 반말 절대 금지. X: ~해,~있어,~좋아,~거야 / O: ~해요,~있어요,~좋아요,~거예요. [한줄평] 20자 내외.

응답은 아래 JSON만 (순서 유지):
{"items":[{"detail":"...","shortMessage":"...","luckyColor":"...","luckyItem":"..."}, ...]}
빈 색/아이템은 "없음" 또는 빈 문자열.

원문 (번호 순):
"""


def _normalize_space_after_period(text: str) -> str:
    """마침표 뒤에 공백이 없으면 한 칸 넣기."""
    if not text:
        return text
    return re.sub(r"\.([^\s])", r". \1", text)


def _ensure_period_at_end(text: str) -> str:
    """문장 끝이 . ! ? 가 아니면 . 추가."""
    if not text or not text.strip():
        return text
    s = text.strip()
    if s and s[-1] not in ".!?。！？":
        s = s + "."
    return s


def _fix_double_yo(text: str) -> str:
    """끝의 '해요해요' 등 중복 어미 제거."""
    if not text:
        return text
    s = text.strip()
    while s.endswith("해요해요"):
        s = s[:-2].rstrip()
    return s


def _short_message_20(s: str, max_len: int = 20) -> str:
    """한줄평: 첫 문장만, 20자 내외. 문체 변환은 프롬프트에서 수행."""
    if not s:
        return ""
    s = _fix_double_yo(s)
    s = _normalize_space_after_period(s)
    first = (s.split(".")[0] or s).strip()
    if not first:
        return ""
    if len(first) > max_len:
        first = first[:max_len].rstrip()
    return _ensure_period_at_end(first[: max_len + 2].rstrip())


def _normalize_lucky(value: str) -> str:
    """행운의 색/아이템: '없음해요.' 등은 빈 문자열."""
    if not value:
        return ""
    v = value.strip()
    if v in ("없음", "없음해요.", "없어요", "なし"):
        return ""
    v = _fix_double_yo(v)
    v = _normalize_space_after_period(v)
    return v


def _gpt_translate_batch(items: List[HoroscopeItem]) -> Optional[List[HoroscopeItem]]:
    """
    12건을 한 번의 API 호출로 번역. 입력/출력 토큰을 줄여 비용 절감.
    실패 시 None 반환 (호출 측에서 1건씩 폴백).
    """
    if not HAS_GPT or not _openai_client or len(items) != 12:
        return None
    lines = []
    for i, item in enumerate(items, start=1):
        detail = (item.detail or "").strip().replace("\n", " ")
        color = (item.luckyColor or "").strip() or "なし"
        thing = (item.luckyItem or "").strip() or "なし"
        lines.append(f"{i}. detail:{detail} | color:{color} | item:{thing}")
    body = "\n".join(lines)
    content = _BATCH_PROMPT_PREFIX + body
    try:
        resp = _openai_client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[{"role": "user", "content": content}],
            response_format={"type": "json_object"},
        )
        raw = resp.choices[0].message.content
        if not raw:
            return None
        data = json.loads(raw)
        out_items = data.get("items")
        if not isinstance(out_items, list) or len(out_items) != 12:
            return None
        result = []
        for idx, orig in enumerate(items):
            if idx >= len(out_items):
                result.append(orig)
                continue
            o = out_items[idx]
            if not isinstance(o, dict):
                result.append(orig)
                continue
            detail = (o.get("detail") or "").strip()
            if not detail:
                result.append(orig)
                continue
            detail = _ensure_period_at_end(_normalize_space_after_period(detail))
            short_msg = _short_message_20((o.get("shortMessage") or "").strip())
            if not short_msg:
                short_msg = "좋은 하루 되세요."
            lucky_color = _normalize_lucky(o.get("luckyColor") or "")
            lucky_item = _normalize_lucky(o.get("luckyItem") or "")
            result.append(
                HoroscopeItem(
                    date=orig.date,
                    sign=orig.sign,
                    rank=orig.rank,
                    shortMessage=short_msg,
                    detail=detail,
                    luckyColor=lucky_color,
                    luckyItem=lucky_item,
                    moneyScore=orig.moneyScore,
                    loveScore=orig.loveScore,
                    workScore=orig.workScore,
                    healthScore=orig.healthScore,
                )
            )
        return result
    except Exception as e:
        print(f"[WARN] GPT 배치 번역 실패: {e}")
        return None


def translate_items_to_korean(items: List[HoroscopeItem]) -> List[HoroscopeItem]:
    """
    한국어 번역본 생성. OPENAI_API_KEY가 있으면 GPT로만 번역 (배치 우선, 실패 시 1건씩).
    GPT 없으면 원본 그대로 반환.
    """
    if HAS_GPT and _openai_client:
        batch = _gpt_translate_batch(items)
        if batch is not None:
            return batch
        result: List[HoroscopeItem] = []
        for item in items:
            ko = _gpt_translate_one_item(item)
            if ko is not None:
                result.append(ko)
            else:
                result.append(item)
            time.sleep(0.3)
        return result

    # GPT 없음: 한국어 번역본 생성 불가 (원본만 저장하려면 --no-translate 없이 실행 시 _jp만 있음)
    return items


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--output",
        default="data",
        help="JSON 파일을 저장할 디렉터리 (기본: data)",
    )
    parser.add_argument(
        "--no-translate",
        action="store_true",
        help="한국어 번역본(_kr.json) 생략, 원본(_jp.json)만 저장",
    )
    args = parser.parse_args()

    today = dt.date.today()
    html = fetch_html()
    items = parse_horoscopes(html, target_date=today)

    if not items:
        print("[WARN] 운세 데이터를 한 건도 파싱하지 못했습니다. CSS 셀렉터를 점검해 주세요.")
        return

    os.makedirs(args.output, exist_ok=True)
    base = today.isoformat()

    # 1) 원본(일본어): 순위, 일본어 원문, 상세운 점수
    payload_ja = to_payload(today, items)
    path_ja = os.path.join(args.output, f"{base}_jp.json")
    with open(path_ja, "w", encoding="utf-8") as f:
        json.dump(payload_ja, f, ensure_ascii=False, indent=2)
    print(f"[INFO] 원본 저장: {path_ja}")

    # 2) 번역본(한국어): 동일 구조, shortMessage/detail/luckyColor/luckyItem만 한국어
    if not args.no_translate:
        if HAS_GPT:
            items_ko = translate_items_to_korean(items)
            payload_ko = to_payload(today, items_ko)
            path_ko = os.path.join(args.output, f"{base}_kr.json")
            with open(path_ko, "w", encoding="utf-8") as f:
                json.dump(payload_ko, f, ensure_ascii=False, indent=2)
            print(f"[INFO] 번역본 저장: {path_ko}" + (" (GPT)" if HAS_GPT else ""))
        else:
            print("[WARN] OPENAI_API_KEY가 없어 한국어 번역본을 생성하지 않습니다. _jp.json만 저장되었습니다.")


if __name__ == "__main__":
    main()

