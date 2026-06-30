# claude-widget

Claude Code 사용량을 데스크톱에 띄워두는 Windows 플로팅 위젯.
이번 달 누적 비용과 현재 5시간 빌링 블록 상태를 한눈에 볼 수 있습니다.

> 변경 내역은 [CHANGELOG.md](CHANGELOG.md) 참고

## 설치 (권장)

PowerShell에 아래 한 줄을 붙여넣으면 끝입니다. 최신 버전을 `%LOCALAPPDATA%\ClaudeWidget`에 설치하고 시작메뉴 바로가기 생성 + 실행까지 한 번에 합니다. **관리자 권한 불필요, SmartScreen 경고 없음.**

```powershell
powershell -ExecutionPolicy Bypass -Command "iex (irm 'https://raw.githubusercontent.com/chm9948/claude-widget/main/setup.ps1')"
```

제거:

```powershell
powershell -ExecutionPolicy Bypass -Command "$ClaudeWidgetUninstall=$true; iex (irm 'https://raw.githubusercontent.com/chm9948/claude-widget/main/setup.ps1')"
```

## 기능

- **이번 달 누적 비용** — 큰 숫자 + 월 배지, 모델별 비용 막대
- **현재 빌링 블록** — 사용률 %, 블록 종료까지 남은 시간(실시간)
- **시스템 트레이 상주** — 좌클릭으로 표시/숨김 토글, 우클릭 메뉴(열기 · 숨기기 · Windows 시작 시 자동 실행 · 종료). 헤더 ✕ 는 트레이로 숨김
- **최소화(🗕)** — 금액과 사용률만 한 줄로 축소, 🗗 로 복원
- **자동 업데이트** — 새 버전이 나오면 ⓘ·트레이에 빨간 점 표시. ⓘ 패널의 "업데이트" 한 번이면 최신으로 재설치·재시작
- **ⓘ 정보 패널** — 문의 메일 · 이슈 링크 · 버전
- 라이트/다크 테마, 투명도 슬라이더, 드래그 이동, 항상 위(Topmost)

## 요구 사항

- Windows + PowerShell 5.1 (Desktop)
- Node.js / `npx` — 비용 데이터(`ccusage`) 조회용
- 로그인된 Claude Code — 사용량 API 토큰(`~/.claude/.credentials.json`) 사용

## 수동 실행 (선택)

설치 스크립트를 쓰지 않고 exe를 직접 받아 실행할 수도 있습니다: **[claude-widget.exe](https://github.com/chm9948/claude-widget/raw/main/claude-widget.exe)**

> 직접 받은 exe는 서명이 없어 최초 1회 SmartScreen이 막을 수 있습니다 → **추가 정보 → 실행**, 또는 파일 우클릭 → 속성 → **차단 해제**. (설치 스크립트를 쓰면 생략됩니다.)

## 만든이

최현민 · 문의: hmchoi@page1.co.kr · GxP Page1
