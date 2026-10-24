#!/usr/bin/env bash
# Status line modeled on the spaceship prompt: dir, git branch, then model, context, usage limits.
input=$(cat)
j() { echo "$input" | jq -r "$1 // empty" 2>/dev/null; }

cwd=$(j '.workspace.current_dir'); [ -z "$cwd" ] && cwd=$(j '.cwd'); [ -z "$cwd" ] && cwd=$PWD
case "$cwd" in "$HOME"|"$HOME"/*) dir="~${cwd#"$HOME"}" ;; *) dir="$cwd" ;; esac

out=$(printf '\033[1;36m%s\033[0m' "$dir")

branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null \
  || git -C "$cwd" --no-optional-locks rev-parse --short HEAD 2>/dev/null)
[ -n "$branch" ] && out="$out $(printf 'on \033[1;35m %s\033[0m' "$branch")"

model=$(j '.model.display_name')
[ -n "$model" ] && out="$out $(printf '\033[2m· %s\033[0m' "$model")"

ctx=$(j '.context_window.used_percentage')
[ -n "$ctx" ] && out="$out $(printf '\033[2m· ctx %.0f%%\033[0m' "$ctx")"

fmt_reset() { # epoch, date format
  [ -n "$1" ] && date -d "@$1" "+$2" 2>/dev/null
}

limits=""
five=$(j '.rate_limits.five_hour.used_percentage')
if [ -n "$five" ]; then
  seg=$(printf '5h: %.0f%%' "$five")
  r=$(fmt_reset "$(j '.rate_limits.five_hour.resets_at')" '%-I:%M%P')
  [ -n "$r" ] && seg="$seg (resets $r)"
  limits="$seg"
fi
week=$(j '.rate_limits.seven_day.used_percentage')
if [ -n "$week" ]; then
  seg=$(printf '7d: %.0f%%' "$week")
  r=$(fmt_reset "$(j '.rate_limits.seven_day.resets_at')" '%a %-I:%M%P')
  [ -n "$r" ] && seg="$seg (resets $r)"
  limits="${limits:+$limits · }$seg"
fi
[ -n "$limits" ] && out="$out $(printf '\033[33m· %s\033[0m' "$limits")"

printf '%s\n' "$out"
