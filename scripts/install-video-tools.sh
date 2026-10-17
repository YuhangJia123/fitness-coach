#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: install-video-tools.sh [--all] [--bilibili] [--douyin] [--xiaohongshu] [--temporary] [--dry-run]

Installs search-only tools. It never logs in and never reads or stores credentials.
EOF
}

DRY_RUN=0
INSTALL_BILIBILI=0
INSTALL_DOUYIN=0
INSTALL_XIAOHONGSHU=0
TEMPORARY=0

while (($# > 0)); do
  case "$1" in
    --all)
      INSTALL_BILIBILI=1
      INSTALL_DOUYIN=1
      INSTALL_XIAOHONGSHU=1
      shift
      ;;
    --bilibili)
      INSTALL_BILIBILI=1
      shift
      ;;
    --douyin)
      INSTALL_DOUYIN=1
      shift
      ;;
    --xiaohongshu)
      INSTALL_XIAOHONGSHU=1
      shift
      ;;
    --temporary)
      TEMPORARY=1
      shift
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if ((INSTALL_BILIBILI == 0 && INSTALL_DOUYIN == 0 && INSTALL_XIAOHONGSHU == 0)); then
  INSTALL_BILIBILI=1
  INSTALL_DOUYIN=1
  INSTALL_XIAOHONGSHU=1
fi

TOOLS_DIR="${FITNESS_COACH_TOOLS_DIR:-${HOME}/.local/share/fitness-coach/video-tools}"
BIN_DIR="$TOOLS_DIR/bin"
PYTHON_BIN="${FITNESS_COACH_PYTHON:-}"

if ((TEMPORARY)); then
  if [[ -n "${FITNESS_COACH_TEMP_DIR:-}" ]]; then
    TOOLS_DIR="$FITNESS_COACH_TEMP_DIR"
  elif ((DRY_RUN)); then
    TOOLS_DIR="${TMPDIR:-/tmp}/fitness-coach-tools.TEMP"
  else
    TOOLS_DIR="$(mktemp -d "${TMPDIR:-/tmp}/fitness-coach-tools.XXXXXX")"
  fi
  BIN_DIR="$TOOLS_DIR/bin"
fi

say() {
  printf '%s\n' "$*"
}

run() {
  if ((DRY_RUN)); then
    printf '+ '
    printf '%q ' "$@"
    printf '\n'
  else
    "$@"
  fi
}

choose_python() {
  if [[ -n "$PYTHON_BIN" ]] && command -v "$PYTHON_BIN" >/dev/null 2>&1; then
    return
  fi
  for candidate in python3.12 python3.11 python3 python; do
    if command -v "$candidate" >/dev/null 2>&1; then
      PYTHON_BIN="$candidate"
      return
    fi
  done
  echo "Python 3.10+ is required; set FITNESS_COACH_PYTHON to its executable." >&2
  exit 1
}

python_version_ok() {
  "$PYTHON_BIN" - <<'PY'
import sys
raise SystemExit(0 if sys.version_info >= (3, 10) else 1)
PY
}

if ((INSTALL_BILIBILI || INSTALL_DOUYIN)); then
  choose_python
  if ! python_version_ok; then
    echo "$PYTHON_BIN is older than Python 3.10; set FITNESS_COACH_PYTHON to Python 3.10+." >&2
    exit 1
  fi
elif [[ -z "$PYTHON_BIN" ]]; then
  for candidate in python3.12 python3.11 python3; do
    if command -v "$candidate" >/dev/null 2>&1; then
      PYTHON_BIN="$candidate"
      if ! python_version_ok; then
        PYTHON_BIN=""
      fi
      break
    fi
  done
fi

if ((DRY_RUN == 0)); then
  mkdir -p "$BIN_DIR"
fi

install_python_tool() {
  local env_name="$1"
  shift
  local venv_dir="$TOOLS_DIR/venvs/$env_name"

  run mkdir -p "$TOOLS_DIR/venvs"
  run "$PYTHON_BIN" -m venv "$venv_dir"
  run "$venv_dir/bin/python" -m pip install --upgrade pip
  run "$venv_dir/bin/python" -m pip install --upgrade "$@"
}

if ((INSTALL_BILIBILI)); then
  say "Installing Bilibili search tool..."
  install_python_tool bilibili bilibili-cli
  run ln -sfn "$TOOLS_DIR/venvs/bilibili/bin/bili" "$BIN_DIR/bili"
fi

if ((INSTALL_DOUYIN)); then
  say "Installing Douyin search tool and Chromium..."
  install_python_tool douyin dy-cli playwright
  run "$TOOLS_DIR/venvs/douyin/bin/playwright" install chromium
  run ln -sfn "$TOOLS_DIR/venvs/douyin/bin/dy" "$BIN_DIR/dy"
fi

if ((INSTALL_XIAOHONGSHU)); then
  case "$(uname -s):$(uname -m)" in
    Darwin:arm64)
      say "Preparing Xiaohongshu macOS Apple Silicon binaries..."
      if ((DRY_RUN)); then
        say "+ download xiaohongshu-login-darwin-arm64 and xiaohongshu-mcp-darwin-arm64 from the latest GitHub release"
      else
        command -v curl >/dev/null 2>&1 || {
          echo "curl is required for the Xiaohongshu release download." >&2
          exit 1
        }
        release_json="$(curl -fsSL -H 'Accept: application/vnd.github+json' https://api.github.com/repos/xpzouying/xiaohongshu-mcp/releases/latest)"
        for asset in xiaohongshu-login-darwin-arm64 xiaohongshu-mcp-darwin-arm64; do
          if [[ -n "$PYTHON_BIN" ]]; then
            url="$(printf '%s' "$release_json" | "$PYTHON_BIN" -c 'import json,sys; name=sys.argv[1]; data=json.load(sys.stdin); print(next((a["browser_download_url"] for a in data.get("assets", []) if a.get("name")==name), ""))' "$asset")"
          elif command -v jq >/dev/null 2>&1; then
            url="$(printf '%s' "$release_json" | jq -r --arg name "$asset" '.assets[] | select(.name == $name) | .browser_download_url' | head -n 1)"
          else
            echo "Xiaohongshu release selection requires Python 3.10+ or jq; use official search links or install one of these optional dependencies." >&2
            exit 1
          fi
          if [[ -z "$url" ]]; then
            echo "Could not find release asset: $asset" >&2
            exit 1
          fi
          curl -fsSL "$url" -o "$BIN_DIR/$asset"
          chmod 0755 "$BIN_DIR/$asset"
        done
      fi
      ;;
    *)
      say "Xiaohongshu automatic binary setup is only included for macOS Apple Silicon."
      say "Use the read-only server or browser-mcp documented in references/video-tool-evaluation.md for this platform."
      ;;
  esac
fi

say "Selected search tools are prepared under: $TOOLS_DIR"
if ((TEMPORARY)); then
  say "This is a temporary environment; remove it after the search: rm -rf '$TOOLS_DIR'"
fi
if ((INSTALL_BILIBILI)); then
  say "Bilibili search: $BIN_DIR/bili search '动作关键词' --type video --max 3 --yaml"
fi
if ((INSTALL_DOUYIN)); then
  say "Douyin login: $BIN_DIR/dy init"
fi
if [[ "$(uname -s):$(uname -m)" == "Darwin:arm64" && $INSTALL_XIAOHONGSHU -eq 1 ]]; then
  say "Xiaohongshu login: $BIN_DIR/xiaohongshu-login-darwin-arm64"
  say "Xiaohongshu service: $BIN_DIR/xiaohongshu-mcp-darwin-arm64"
fi
