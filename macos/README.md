# claude-widget (macOS 메뉴바)

[claude-widget](../README.md)(Windows 플로팅 위젯)의 **macOS 메뉴바 버전**입니다.
[SwiftBar](https://swiftbar.app) 플러그인(`claude-widget.5m.py`)으로 동작하며, 메뉴바에 이번 달 누적 비용과 현재 5시간 빌링 블록 사용률을 `"$12.34 · 41%"` 형태로 표시합니다. 드롭다운에서 모델별 비용과 현재 블록 남은 시간을 볼 수 있습니다.

## 요구 사항

- macOS + [SwiftBar](https://swiftbar.app) (`brew install --cask swiftbar`)
- Node.js / `npx` — 비용 데이터(`ccusage`) 조회용
- 로그인된 Claude Code — 사용량 API 토큰을 macOS 키체인의 `Claude Code-credentials` 항목에서 읽습니다 (일부 환경은 `~/.claude/.credentials.json` 폴백)

## 설치 (한 줄)

SwiftBar를 한 번 실행해 플러그인 폴더를 지정한 뒤, 터미널에 아래 한 줄을 붙여넣으면 끝입니다.

```bash
bash <(curl -fsSL 'https://raw.githubusercontent.com/chm9948/claude-widget/main/macos/install.sh')
```

플러그인 폴더를 자동 탐지해 `claude-widget.5m.py`를 복사하고 SwiftBar를 새로고침합니다. **관리자 권한 불필요.**

## 수동 설치

1. [`claude-widget.5m.py`](claude-widget.5m.py)를 내려받아 SwiftBar 플러그인 폴더에 복사
2. 실행 권한 부여: `chmod +x claude-widget.5m.py`
3. SwiftBar 새로고침: `open -g 'swiftbar://refreshallplugins'` (또는 SwiftBar 메뉴에서 Refresh All)

## 데이터 소스

Windows 위젯과 동일한 로직을 사용하며 5분마다 갱신합니다.

1. **ccusage** — `npx ccusage@latest claude monthly --json` / `... blocks --json`. 로컬 `~/.claude/projects/**/*.jsonl`에서 읽으므로 Claude Code CLI 사용량만 집계 (이번 달 비용 + 모델별 비용, 활성 블록 비용)
2. **Anthropic usage API** — `GET https://api.anthropic.com/api/oauth/usage` (키체인의 OAuth 토큰 사용). `five_hour.utilization`(사용률 %)과 `five_hour.resets_at`(블록 종료 시각)은 `/usage`가 보여주는 값 그대로이며, CLI뿐 아니라 브라우저·데스크톱 앱 등 **모든 클라이언트**의 사용량을 반영하는 서버 측 기준값입니다

블록 사용률/종료 시각은 API 값을 우선 사용합니다. API 호출이 실패하면 마지막 성공값을 캐시(`~/.cache/claude-widget/`)에서 계속 표시하고(429는 15분, 기타 오류는 5분 백오프 후 재시도), 캐시조차 없을 때만 ccusage `endTime`과 폴백 공식 `max(tokens/20,446,221, cost/$13.44)`를 사용합니다.

## 제거

```bash
rm '<SwiftBar 플러그인 폴더>/claude-widget.5m.py'
rm -rf ~/.cache/claude-widget
```

플러그인 폴더 경로는 `defaults read com.ameba.SwiftBar PluginDirectory`로 확인할 수 있습니다.

## 만든이

최현민 · 문의: hmchoi@page1.co.kr · GxP Page1
