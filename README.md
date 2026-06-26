# claude-widget

Claude Code 사용량을 데스크톱에 띄워두는 Windows 플로팅 위젯.
이번 달 누적 비용과 현재 5시간 빌링 블록 상태를 항상 한눈에 볼 수 있습니다.

> 버전: v1.3.0 · 변경 내역은 [CHANGELOG.md](CHANGELOG.md) 참고

## 화면 구성

- **이번 달 누적 비용** — 큰 숫자로 표시 + 월 배지
- **모델별 비용 막대** — 모델별 비용 비중을 막대로 표시
- **현재 빌링 블록** — 진행률 막대, 사용률 %, 블록 종료까지 남은 시간(실시간)
- **하단 바** — 투명도 슬라이더 · 갱신 카운트다운 · 수동 새로고침(⟳)
- **ⓘ 정보 패널** — 헤더의 ⓘ 클릭 시 문의 메일·이슈 링크·버전 표시. 새 버전이 있으면 ⓘ에 빨간 점과 다운로드 링크가 뜸 (다시 클릭하면 접힘)
- **최소화** — 헤더의 ─ 버튼으로 금액만 한 줄로 축소, ▢ 로 복원
- **테마 토글** — 라이트/다크 전환(☾/☀)

창은 드래그로 이동할 수 있고 항상 위(Topmost)에 떠 있습니다.

## 실행

```powershell
# 소스 직접 실행
powershell -ExecutionPolicy Bypass -File claude-widget.ps1

# 또는 컴파일된 바이너리 실행
.\claude-widget.exe
```

## 다운로드

최신 실행 파일: **[claude-widget.exe](https://github.com/chm9948/claude-widget/raw/main/claude-widget.exe)** (main 기준 최신 버전)

## 최초 실행 안내 (중요)

코드 서명이 없는 실행 파일이라, 인터넷에서 받은 `claude-widget.exe`를 처음 실행하면 Windows가 보호 차원에서 막을 수 있습니다. **해당 PC에서 최초 1회만** 아래처럼 처리하면 되고, 이후로는 바로 실행됩니다.

1. "Windows의 PC를 보호했습니다(Windows protected your PC)" 창이 뜨면 → **추가 정보(More info)** → **실행(Run anyway)** 버튼
2. 또는 실행 전에 파일 **우클릭 → 속성 → (맨 아래) 차단 해제 체크 → 확인**
3. 백신이 파일을 격리하면(ps2exe 특성상 오탐이 날 수 있음) 해당 파일을 백신 **예외/허용 목록**에 추가

> 같은 사내 네트워크의 공유 폴더로 전달받은 경우에는 위 경고가 뜨지 않을 수 있습니다.
>
> 위 과정이 번거로우면 소스(`claude-widget.ps1`)를 직접 실행해도 됩니다: `powershell -ExecutionPolicy Bypass -File claude-widget.ps1`

## 요구 사항

- Windows + PowerShell 5.1 (Desktop)
- Node.js / `npx` — 비용 데이터(`ccusage`) 조회용
- 로그인된 Claude Code — 사용량 API 토큰(`~/.claude/.credentials.json`)을 사용

## 데이터 소스

| 표시 항목 | 출처 |
|---|---|
| 월 누적 비용 · 모델별 내역 | `npx ccusage@latest claude monthly --json` |
| 블록 종료 시각 · 사용률 % | Anthropic `oauth/usage` API의 `five_hour` (= `/usage`와 동일, 브라우저·앱 등 모든 클라이언트 사용량 포함) |

- 사용량 API는 자동 갱신 주기(기본 5분)마다 호출하며, 마지막 성공값을 캐시로 유지합니다.
- API가 일시적으로 실패(예: 429 rate limit)하면 폴백 공식으로 튀지 않고 캐시값을 계속 표시하며, 일정 시간 후 재시도합니다.

## 구조

단일 파일 WPF 앱(PowerShell). XAML을 인라인 here-string으로 정의하고 `XamlReader`로 로드합니다.
백그라운드 runspace가 데이터를 조회해 스레드 안전 큐로 UI에 전달하고, UI 스레드의 타이머들이 화면을 갱신합니다.
자세한 아키텍처는 [CLAUDE.md](CLAUDE.md) 참고.

## 빌드 / 배포

`ps2exe`로 `.ps1`을 `.exe`로 컴파일합니다.

```powershell
Invoke-ps2exe -inputFile claude-widget.ps1 -outputFile claude-widget.exe -noConsole
```

버전을 올릴 때는 소스의 `$script:appVersion`, `CHANGELOG.md`, ⓘ 정보 패널의 버전 값을 함께 맞춥니다.

## 만든이

최현민 · 문의: hmchoi@page1.co.kr · GxP Page1
