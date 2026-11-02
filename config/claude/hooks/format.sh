#!/usr/bin/env bash
# PostToolUse hook: format the file Claude just wrote, then lint it.
# Failures go to stderr with exit 2, which Claude Code passes back to Claude.
PATH="$HOME/.local/share/nvim/mason/bin:$PATH"

file=$(jq -r '.tool_input.file_path // empty')
[ -f "$file" ] || exit 0
cd "$(dirname "$file")" || exit 0
name=$(basename "$file")

problems=""
# run <tool> <args...>: skip a missing tool, keep the output of a failing one.
run() {
  command -v "$1" >/dev/null || return 0
  local out
  out=$("$@" 2>&1) || problems+="\$ $*"$'\n'"$(head -n 40 <<<"$out")"$'\n'
}

# up <name>: print the nearest directory, from here upward, that holds <name>.
up() {
  local d=$PWD
  while [ "$d" != / ]; do
    [ -e "$d/$1" ] && echo "$d" && return
    d=$(dirname "$d")
  done
  return 1
}

case "$name" in
  *.js | *.mjs | *.cjs | *.jsx | *.ts | *.mts | *.cts | *.tsx | *.json | *.jsonc | \
    *.css | *.scss | *.html | *.md | *.yaml | *.yml)
    run prettier --write --log-level warn "$name"
    ;;
  *.py)
    run ruff format "$name"
    run ruff check --quiet "$name"
    ;;
  *.lua)
    run stylua --search-parent-directories "$name"
    ;;
  *.sh | *.bash)
    # shfmt ignores .editorconfig when given style flags.
    if up .editorconfig >/dev/null; then
      run shfmt -w "$name"
    else
      run shfmt -w -i 2 -ci "$name"
    fi
    ;;
  *.go)
    run gofmt -w "$name"
    ;;
  *.rs)
    edition=$(grep -m1 -oP '^edition\s*=\s*"\K[0-9]+' "$(up Cargo.toml)/Cargo.toml" 2>/dev/null)
    run rustfmt --edition "${edition:-2021}" "$name"
    ;;
  *.c | *.h | *.cc | *.cpp | *.cxx | *.hpp | *.hh)
    run clang-format -i "$name"
    ;;
  *.qml)
    run qmlformat -i "$name"
    run qmllint "$name"
    ;;
esac

[ -z "$problems" ] && exit 0
printf '%s' "$problems" >&2
exit 2
