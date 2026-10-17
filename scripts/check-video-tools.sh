#!/usr/bin/env bash

set -u

TOOLS_DIR="${FITNESS_COACH_TOOLS_DIR:-${HOME}/.local/share/fitness-coach/video-tools}"
BIN_DIR="$TOOLS_DIR/bin"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

say() {
  printf '%s\n' "$*"
}

check_command() {
  local label="$1"
  local command_name="$2"
  if command -v "$command_name" >/dev/null 2>&1; then
    say "FITNESS_COACH_CHECK ${label}=available path=$(command -v "$command_name")"
  else
    say "FITNESS_COACH_CHECK ${label}=missing"
  fi
}

find_python() {
  local candidate
  for candidate in python3.12 python3.11 python3 python; do
    if command -v "$candidate" >/dev/null 2>&1; then
      if "$candidate" -c 'import sys; raise SystemExit(0 if sys.version_info >= (3, 10) else 1)' >/dev/null 2>&1; then
        printf '%s\n' "$candidate"
        return 0
      fi
    fi
  done
  return 1
}

say "Fitness Coach dependency preflight"
say "FITNESS_COACH_CHECK core_runtime=available runtime=bash"
say "FITNESS_COACH_CHECK core_python=not_required"

if python_bin="$(find_python)"; then
  say "FITNESS_COACH_CHECK python310=available path=$(command -v "$python_bin")"
  if "$python_bin" -m venv --help >/dev/null 2>&1; then
    say "FITNESS_COACH_CHECK python_venv=available"
  else
    say "FITNESS_COACH_CHECK python_venv=missing"
  fi
  if "$python_bin" -m pip --version >/dev/null 2>&1; then
    say "FITNESS_COACH_CHECK python_pip=available"
  else
    say "FITNESS_COACH_CHECK python_pip=missing"
  fi
  if "$python_bin" -c 'import reportlab' >/dev/null 2>&1; then
    say "FITNESS_COACH_CHECK pdf_reportlab=available"
  else
    say "FITNESS_COACH_CHECK pdf_reportlab=missing"
  fi
else
  say "FITNESS_COACH_CHECK python310=missing"
  say "FITNESS_COACH_CHECK python_venv=not_available"
  say "FITNESS_COACH_CHECK python_pip=not_available"
  say "FITNESS_COACH_CHECK pdf_reportlab=not_available"
fi

if [[ -w "$PROJECT_DIR" ]]; then
  say "FITNESS_COACH_CHECK project_directory=available path=$PROJECT_DIR"
else
  say "FITNESS_COACH_CHECK project_directory=read_only path=$PROJECT_DIR"
fi

TOOLS_PARENT="$TOOLS_DIR"
while [[ ! -e "$TOOLS_PARENT" && "$TOOLS_PARENT" != "/" ]]; do
  TOOLS_PARENT="$(dirname "$TOOLS_PARENT")"
done
if [[ -d "$TOOLS_DIR" && -w "$TOOLS_DIR" ]] || [[ -d "$TOOLS_PARENT" && -w "$TOOLS_PARENT" ]]; then
  say "FITNESS_COACH_CHECK tools_directory=available path=$TOOLS_DIR"
else
  say "FITNESS_COACH_CHECK tools_directory=not_writable path=$TOOLS_DIR"
fi

if [[ -x "$BIN_DIR/bili" ]]; then
  say "FITNESS_COACH_CHECK bilibili_tool=available path=$BIN_DIR/bili"
else
  say "FITNESS_COACH_CHECK bilibili_tool=missing"
fi

if [[ -x "$BIN_DIR/dy" ]]; then
  say "FITNESS_COACH_CHECK douyin_tool=available path=$BIN_DIR/dy"
else
  say "FITNESS_COACH_CHECK douyin_tool=missing"
fi

if [[ -x "$BIN_DIR/xiaohongshu-mcp-darwin-arm64" || -x "$BIN_DIR/xiaohongshu-mcp-linux-amd64" ]]; then
  say "FITNESS_COACH_CHECK xiaohongshu_tool=available path=$BIN_DIR"
else
  say "FITNESS_COACH_CHECK xiaohongshu_tool=missing"
fi

if [[ -x "$TOOLS_DIR/venvs/douyin/bin/playwright" ]]; then
  if "$TOOLS_DIR/venvs/douyin/bin/playwright" install --dry-run chromium >/dev/null 2>&1; then
    say "FITNESS_COACH_CHECK chromium=available"
  else
    say "FITNESS_COACH_CHECK chromium=unknown_or_missing"
  fi
else
  say "FITNESS_COACH_CHECK chromium=not_configured"
fi

check_command curl curl
check_command pdf_renderer pdftoppm

if [[ -f "/System/Library/Fonts/PingFang.ttc" || -f "/System/Library/Fonts/STHeiti Light.ttc" || -f "/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc" || -f "/usr/share/fonts/google-noto-cjk/NotoSansCJK-Regular.ttc" ]]; then
  say "FITNESS_COACH_CHECK pdf_cjk_font=available"
else
  say "FITNESS_COACH_CHECK pdf_cjk_font=missing"
fi

if [[ "$(uname -s)" == "Darwin" ]]; then
  if [[ -d "/Applications/Google Chrome.app" || -d "$HOME/Applications/Google Chrome.app" ]]; then
    say "FITNESS_COACH_CHECK browser=available name=Google_Chrome"
  elif [[ -d "/Applications/Safari.app" ]]; then
    say "FITNESS_COACH_CHECK browser=available name=Safari"
  else
    say "FITNESS_COACH_CHECK browser=unknown"
  fi
else
  say "FITNESS_COACH_CHECK browser=use_system_or_in_app_browser"
fi

say "Core plan generation needs no Python, third-party package, login, or browser automation."
say "Optional platform tools may need Python 3.10+ and, for Douyin, a Chromium browser."
say "If an optional dependency is missing, ask whether to use official browser search links, install to the user tool directory, create a temporary environment, or skip video search."

# Preflight is informational so a missing optional tool never blocks plan generation.
exit 0
