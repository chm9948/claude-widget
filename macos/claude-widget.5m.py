#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# <xbar.title>Claude Widget</xbar.title>
# <xbar.version>v0.1.0</xbar.version>
# <xbar.author>최현민</xbar.author>
# <xbar.author.github>chm9948</xbar.author.github>
# <xbar.desc>Claude Code 월 누적 비용과 활성 결제 블록 상태를 메뉴바에 표시합니다.</xbar.desc>
# <xbar.dependencies>python3,node</xbar.dependencies>
# <xbar.abouturl>https://github.com/chm9948/claude-widget</xbar.abouturl>
# <swiftbar.hideRunInTerminal>true</swiftbar.hideRunInTerminal>
# <swiftbar.hideSwiftBar>true</swiftbar.hideSwiftBar>
"""SwiftBar 플러그인: Claude Code 사용량 위젯 (윈도우 claude-widget.ps1 의 macOS 포팅).

데이터 소스 (윈도우판과 동일한 우선순위):
1. ccusage — 월 누적 비용/모델별 분해, 활성 블록 비용
2. Anthropic usage API — five_hour.utilization / five_hour.resets_at (서버측 진실값)
   실패 시 마지막 성공값 캐시 사용 (429 는 15분, 기타 5분 백오프).
   캐시에 없는 필드만 ccusage endTime / 폴백 공식으로 채움 (필드별 폴백).
"""

import json
import math
import os
import re
import subprocess
import urllib.request
from datetime import datetime, timedelta, timezone

APP_VERSION = "v0.1.0"
REPO_URL = "https://github.com/chm9948/claude-widget"
USAGE_API_URL = "https://api.anthropic.com/api/oauth/usage"
CACHE_DIR = os.path.expanduser("~/.cache/claude-widget")
CACHE_FILE = os.path.join(CACHE_DIR, "usage-cache.json")

# 폴백 공식 상수 (윈도우판과 동일: max(tokens/20446221, cost/13.44) * 100)
FALLBACK_TOKEN_LIMIT = 20_446_221
FALLBACK_COST_LIMIT = 13.44

# 백오프 (분)
BACKOFF_RATE_LIMIT_MIN = 15
BACKOFF_OTHER_MIN = 5


# ---------------------------------------------------------------- 환경

def setup_path():
    """SwiftBar 는 최소 PATH 로 실행되므로 homebrew 경로를 앞에 추가."""
    extra = "/opt/homebrew/bin:/usr/local/bin"
    cur = os.environ.get("PATH", "")
    if not cur.startswith(extra):
        os.environ["PATH"] = extra + (":" + cur if cur else "")


# ---------------------------------------------------------------- 유틸

def parse_iso(s):
    """ISO 8601 문자열 → aware datetime (UTC 기본). 실패/빈값은 None."""
    if not s:
        return None
    try:
        t = str(s).strip()
        if t.endswith("Z"):
            t = t[:-1] + "+00:00"
        dt = datetime.fromisoformat(t)
        if dt.tzinfo is None:
            dt = dt.replace(tzinfo=timezone.utc)
        return dt
    except (ValueError, TypeError):
        return None


def clean_model_name(name):
    """modelName 에서 ^claude- 접두사와 -\\d{8,}$ 빌드번호 제거."""
    n = re.sub(r"^claude-", "", str(name))
    n = re.sub(r"-\d{8,}$", "", n)
    return n


def format_remaining(end_dt, now=None):
    """블록 종료까지 남은 시간 문자열. 반드시 floor (반올림 금지).
    예: '2시간 13분 남음 (15:00 종료)'. 종료 시각은 로컬타임."""
    if end_dt is None:
        return None
    now = now or datetime.now(timezone.utc)
    secs = (end_dt - now).total_seconds()
    if secs <= 0:
        return None
    total_min = math.floor(secs / 60)
    hours = math.floor(total_min / 60)
    mins = total_min % 60
    end_local = end_dt.astimezone().strftime("%H:%M")
    if hours > 0:
        return "{}시간 {}분 남음 ({} 종료)".format(hours, mins, end_local)
    if mins == 0:
        return "1분 미만 남음 ({} 종료)".format(end_local)
    return "{}분 남음 ({} 종료)".format(mins, end_local)


# ---------------------------------------------------------------- ccusage

def run_ccusage(subcommand):
    """`npx -y ccusage@latest claude <subcommand> --json` 실행 후 JSON 파싱.
    npx 콜드런 대비 timeout 120초. 실패 시 예외."""
    proc = subprocess.run(
        ["npx", "-y", "ccusage@latest", "claude", subcommand, "--json"],
        capture_output=True, text=True, timeout=120,
    )
    if proc.returncode != 0:
        raise RuntimeError("ccusage {} exited {}".format(subcommand, proc.returncode))
    out = proc.stdout.strip()
    # npx 가 JSON 앞에 잡음을 출력하는 경우 대비
    start = out.find("{")
    if start < 0:
        raise RuntimeError("ccusage {}: no JSON in output".format(subcommand))
    return json.loads(out[start:])


def get_monthly():
    return run_ccusage("monthly")


def get_blocks():
    return run_ccusage("blocks")


def pick_month(monthly_list, now=None):
    """현재 yyyy-MM 매치 우선, 없으면 마지막 항목 (윈도우판 동일)."""
    if not monthly_list:
        return None
    now = now or datetime.now()
    cur = now.strftime("%Y-%m")
    for m in monthly_list:
        if m.get("month") == cur:
            return m
    return monthly_list[-1]


def find_active_block(blocks_data):
    for b in (blocks_data or {}).get("blocks", []):
        if b.get("isActive"):
            return b
    return None


# ---------------------------------------------------------------- OAuth / usage API

def get_oauth_token():
    """macOS 키체인 우선, 폴백으로 ~/.claude/.credentials.json. 없으면 None."""
    try:
        proc = subprocess.run(
            ["security", "find-generic-password", "-s", "Claude Code-credentials", "-w"],
            capture_output=True, text=True, timeout=15,
        )
        if proc.returncode == 0 and proc.stdout.strip():
            data = json.loads(proc.stdout)
            token = (data.get("claudeAiOauth") or {}).get("accessToken")
            if token:
                return token
    except Exception:
        pass
    try:
        with open(os.path.expanduser("~/.claude/.credentials.json"), "r", encoding="utf-8") as f:
            data = json.load(f)
        return (data.get("claudeAiOauth") or {}).get("accessToken")
    except Exception:
        return None


def fetch_usage_api(token):
    """usage API 호출 → (utilization 0-100, resets_at ISO). 실패 시 예외."""
    req = urllib.request.Request(USAGE_API_URL, headers={
        "Authorization": "Bearer " + token,
        "anthropic-beta": "oauth-2025-04-20",
    })
    with urllib.request.urlopen(req, timeout=15) as resp:
        data = json.loads(resp.read().decode("utf-8"))
    five_hour = data.get("five_hour") or {}
    return five_hour.get("utilization"), five_hour.get("resets_at")


# ---------------------------------------------------------------- 캐시 / 백오프

def load_cache():
    try:
        with open(CACHE_FILE, "r", encoding="utf-8") as f:
            data = json.load(f)
        if isinstance(data, dict):
            return data
    except Exception:
        pass
    return {}


def save_cache(cache):
    try:
        os.makedirs(CACHE_DIR, exist_ok=True)
        # 원자적 쓰기: 수동 새로고침과 정기 실행이 겹쳐도 파일이 잘리지 않도록
        tmp = CACHE_FILE + ".tmp.{}".format(os.getpid())
        with open(tmp, "w", encoding="utf-8") as f:
            json.dump(cache, f)
        os.replace(tmp, CACHE_FILE)
    except Exception:
        pass  # 캐시 저장 실패는 치명적이지 않음


def resolve_block(active_block, now=None):
    """블록 종료시각/진행률 결정 (윈도우판 로직의 파일 기반 포팅).

    반환: {"pct": float|None, "end": datetime|None, "source": "api"|"ccusage"} 또는 None.
    - 백오프 중이 아니면 API 호출; 성공 시 값이 있는 필드만 캐시 갱신,
      실패 시 429/rate=15분·기타 5분 백오프.
    - 필드별 폴백 (윈도우판 동일): end 는 캐시값이 없거나 이미 지났으면 ccusage
      endTime, pct 는 캐시값이 없으면 폴백 공식. source 는 폴백이 하나라도
      쓰였으면 "ccusage".
    """
    now = now or datetime.now(timezone.utc)
    cache = load_cache()

    blocked_until = parse_iso(cache.get("apiBlockedUntilIso"))
    if not (blocked_until and now < blocked_until):
        try:
            token = get_oauth_token()
            if not token:
                raise RuntimeError("no oauth token")
            pct, end_iso = fetch_usage_api(token)
            # 값이 실제로 있을 때만 갱신 (윈도우판 동일) — null 필드 응답이
            # 마지막 성공값을 지우지 않도록 기존 캐시 필드는 보존한다.
            if end_iso:
                cache["cachedEndIso"] = end_iso
            if pct is not None:
                cache["cachedPct"] = pct
            cache["apiBlockedUntilIso"] = None
            save_cache(cache)
        except Exception as e:
            msg = str(e).lower()
            mins = BACKOFF_RATE_LIMIT_MIN if ("429" in msg or "rate" in msg) else BACKOFF_OTHER_MIN
            cache["apiBlockedUntilIso"] = (now + timedelta(minutes=mins)).isoformat()
            save_cache(cache)

    # 필드별 병합 (윈도우판 동일): 캐시값 우선, 필드가 비면 그 필드만 ccusage 폴백.
    pct = cache.get("cachedPct")
    end = parse_iso(cache.get("cachedEndIso"))

    used_fallback = False
    if active_block:
        # end: 캐시값이 없거나 이미 지났으면 ccusage endTime 으로 폴백
        # (API 장기 실패 중 새 블록이 시작된 경우에도 블록을 표시하기 위함)
        if end is None or end <= now:
            cc_end = parse_iso(active_block.get("endTime"))
            if cc_end is not None:
                end = cc_end
                used_fallback = True
        # pct: 캐시값이 없으면 폴백 공식으로 계산
        if pct is None:
            tokens = active_block.get("totalTokens") or 0
            cost = active_block.get("costUSD") or 0
            pct = max(tokens / FALLBACK_TOKEN_LIMIT, cost / FALLBACK_COST_LIMIT) * 100
            used_fallback = True

    if pct is None and end is None:
        return None

    if pct is not None:
        # API/캐시 경로 포함 항상 0-100 클램프 (윈도우판 동일)
        pct = max(0.0, min(100.0, float(pct)))

    return {"pct": pct, "end": end, "source": "ccusage" if used_fallback else "api"}


# ---------------------------------------------------------------- 출력 (SwiftBar 형식)

def build_error_output(reason):
    return "\n".join([
        "Claude ⚠︎",
        "---",
        reason,
        "새로고침 | refresh=true",
    ])


def build_output(month, active_block, block, now=None):
    """SwiftBar 출력 문자열 생성. 첫 줄 = 메뉴바 타이틀, --- 이후 드롭다운."""
    now = now or datetime.now(timezone.utc)
    total = float(month.get("totalCost") or 0)

    end_dt = block.get("end") if block else None
    pct = block.get("pct") if block else None
    is_active = end_dt is not None and end_dt > now

    # --- 타이틀 ---
    if is_active and pct is not None:
        title = "${:.2f} · {:.0f}%".format(total, pct)
    else:
        title = "${:.2f}".format(total)

    lines = [title, "---"]

    # --- 이번 달 누적 ---
    lines.append("이번 달 누적 · {}".format(month.get("month", "?")))
    lines.append("합계  ${:.2f} | font=Menlo".format(total))
    breakdowns = month.get("modelBreakdowns") or []
    names = [clean_model_name(b.get("modelName", "?")) for b in breakdowns]
    width = max((len(n) for n in names), default=0)
    for name, b in zip(names, breakdowns):
        cost = float(b.get("cost") or 0)
        share = (cost / total * 100) if total > 0 else 0
        lines.append("{}  ${:.2f} ({:.0f}%) | font=Menlo".format(name.ljust(width), cost, share))

    # --- 활성 블록 ---
    if is_active:
        lines.append("---")
        block_cost = active_block.get("costUSD") if active_block else None
        parts = []
        if block_cost is not None:
            parts.append("${:.2f}".format(float(block_cost)))
        if pct is not None:
            parts.append("{:.0f}%".format(pct))
        lines.append("현재 블록  {}".format(" · ".join(parts)) if parts else "현재 블록")
        remaining = format_remaining(end_dt, now)
        if remaining:
            lines.append(remaining)

    # --- 푸터 ---
    lines.append("---")
    lines.append("갱신 {} · {}".format(datetime.now().strftime("%H:%M:%S"), APP_VERSION))
    lines.append("GitHub 저장소 | href={}".format(REPO_URL))
    lines.append("새로고침 | refresh=true")
    return "\n".join(lines)


# ---------------------------------------------------------------- main

def main():
    setup_path()

    # 월 누적 (필수 데이터 — 실패 시 에러 표시)
    try:
        monthly_data = get_monthly()
        month = pick_month(monthly_data.get("monthly") or [])
        if month is None:
            raise RuntimeError("no monthly data")
    except Exception:
        print(build_error_output("ccusage 실행 실패 — node/npx 확인"))
        return

    # 활성 블록 비용 (실패해도 월 데이터는 표시)
    active_block = None
    try:
        active_block = find_active_block(get_blocks())
    except Exception:
        pass

    # 블록 종료/진행률: API(캐시/백오프) 우선, 빈 필드만 ccusage 로 폴백
    try:
        block = resolve_block(active_block)
    except Exception:
        block = None

    print(build_output(month, active_block, block))


if __name__ == "__main__":
    try:
        main()
    except Exception:
        # 어떤 경우에도 traceback 을 메뉴바에 노출하지 않는다
        print(build_error_output("내부 오류 — 플러그인 로그 확인"))
