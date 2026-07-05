#!/usr/bin/env bash
# claude-widget macOS(SwiftBar) 플러그인 설치 스크립트 (관리자 권한 불필요)
#
# 설치:
#   bash <(curl -fsSL 'https://raw.githubusercontent.com/chm9948/claude-widget/main/macos/install.sh')
#
# 제거:
#   SwiftBar 플러그인 폴더의 claude-widget.5m.py 삭제 + rm -rf ~/.cache/claude-widget

set -euo pipefail

PLUGIN_NAME='claude-widget.5m.py'
PLUGIN_URL='https://raw.githubusercontent.com/chm9948/claude-widget/main/macos/claude-widget.5m.py'

echo ''
echo '  Claude Widget (macOS 메뉴바) 설치 중...'

# ── SwiftBar 설치 확인 ───────────────────────────────────────
if ! [ -d '/Applications/SwiftBar.app' ] && ! [ -d "$HOME/Applications/SwiftBar.app" ] \
   && ! mdfind "kMDItemCFBundleIdentifier == 'com.ameba.SwiftBar'" 2>/dev/null | grep -q .; then
    echo ''
    echo '  SwiftBar가 설치되어 있지 않습니다.'
    echo '  아래 명령으로 먼저 설치한 뒤 SwiftBar를 한 번 실행해 주세요:'
    echo ''
    echo '    brew install --cask swiftbar'
    echo ''
    echo '  (Homebrew가 없다면 https://swiftbar.app 에서 직접 받을 수 있습니다.)'
    exit 1
fi

# ── 플러그인 디렉터리 탐지 ───────────────────────────────────
if ! PLUGIN_DIR=$(defaults read com.ameba.SwiftBar PluginDirectory 2>/dev/null); then
    echo ''
    echo '  SwiftBar 플러그인 폴더를 찾지 못했습니다.'
    echo '  SwiftBar를 한 번 실행해 플러그인 폴더를 지정한 뒤 다시 시도해 주세요.'
    exit 1
fi

# ~ 로 시작하는 경로 대응
PLUGIN_DIR="${PLUGIN_DIR/#\~/$HOME}"

if ! [ -d "$PLUGIN_DIR" ]; then
    echo ''
    echo "  플러그인 폴더가 존재하지 않습니다: $PLUGIN_DIR"
    echo '  SwiftBar 설정에서 플러그인 폴더를 다시 지정해 주세요.'
    exit 1
fi

# ── 플러그인 복사 (로컬 파일 우선, 없으면 원격 다운로드) ────
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || true)
DEST="$PLUGIN_DIR/$PLUGIN_NAME"

if [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/$PLUGIN_NAME" ]; then
    cp "$SCRIPT_DIR/$PLUGIN_NAME" "$DEST"
    SRC_DESC="로컬 파일 ($SCRIPT_DIR/$PLUGIN_NAME)"
else
    curl -fsSL "$PLUGIN_URL" -o "$DEST"
    SRC_DESC='GitHub 최신 버전'
fi
chmod +x "$DEST"

# ── SwiftBar 새로고침 ────────────────────────────────────────
open -g 'swiftbar://refreshallplugins' 2>/dev/null || true

echo ''
echo '  설치 완료!'
echo "    위치   : $DEST"
echo "    출처   : $SRC_DESC"
echo '    갱신   : 5분마다 자동 (메뉴에서 수동 새로고침 가능)'
echo '    제거   : 위 플러그인 파일 삭제 + rm -rf ~/.cache/claude-widget'
echo ''
