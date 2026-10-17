#!/usr/bin/env bash
set -eu

# 基础能力探测只描述当前本地进程能确认的事实；聊天客户端能力由适配层判断。
root_dir="${1:-.}"

if [ -r "$root_dir" ]; then
  read_local_files="yes"
else
  read_local_files="no"
fi

if [ -w "$root_dir" ]; then
  write_local_files="yes"
else
  write_local_files="no"
fi

if command -v python3 >/dev/null 2>&1; then
  script_execution="yes"
else
  script_execution="no"
fi

if command -v curl >/dev/null 2>&1; then
  web_access="possible"
else
  web_access="unknown"
fi

if command -v pandoc >/dev/null 2>&1 || command -v tectonic >/dev/null 2>&1; then
  pdf_generation="possible"
else
  pdf_generation="unknown"
fi

printf 'read_local_files=%s\n' "$read_local_files"
printf 'write_local_files=%s\n' "$write_local_files"
printf 'script_execution=%s\n' "$script_execution"
printf 'web_access=%s\n' "$web_access"
printf 'file_upload=client-dependent\n'
printf 'persistent_chat_context=client-dependent\n'
printf 'pdf_generation=%s\n' "$pdf_generation"
