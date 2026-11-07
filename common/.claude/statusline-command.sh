#!/bin/sh
# Left: model | where Claude started (-> where it works, if it moved) | zsh-style path (branch).
# Right-aligned: context usage, 5-hour rate limit, and the lines Claude edited this session.

input=$(cat)

# Missing values become "-" because consecutive tabs would collapse under a whitespace IFS.
IFS='	' read -r model project_dir current_dir context_pct five_hour_pct added removed <<EOF
$(printf '%s' "$input" | jq -r '[
  (.model.display_name // "?"),
  (.workspace.project_dir // .cwd),
  (.workspace.current_dir // .cwd),
  (.context_window.used_percentage | if . == null then "-" else floor end),
  (.rate_limits.five_hour.used_percentage | if . == null then "-" else floor end),
  (.cost.total_lines_added // 0),
  (.cost.total_lines_removed // 0)
] | @tsv')
EOF

esc=$(printf '\033')
reset="${esc}[0m"
dim="${esc}[2m"
bold_magenta="${esc}[1;35m"
cyan="${esc}[36m"
blue="${esc}[34m"
green="${esc}[32m"
yellow="${esc}[33m"
red="${esc}[31m"
bar=$(printf '\342\224\202')
arrow=$(printf '\342\206\222')

abbreviate_home() {
  case $1 in
    "$HOME"*) printf '~%s' "${1#"$HOME"}" ;;
    *) printf '%s' "$1" ;;
  esac
}

percent_color() {
  if [ "$1" -ge 80 ]; then printf '%s' "$red"
  elif [ "$1" -ge 50 ]; then printf '%s' "$yellow"
  else printf '%s' "$green"
  fi
}

# Each *_plain string mirrors the colored one with "x" standing in for a one-column glyph,
# so that ${#...} measures display width for the right alignment.
started=$(basename "$project_dir")
left="${bold_magenta}${model}${reset} ${dim}${bar}${reset} ${cyan}${started}${reset}"
left_plain="${model} x ${started}"
if [ "$current_dir" != "$project_dir" ]; then
  case $current_dir in
    "$project_dir"/*) working=${current_dir#"$project_dir"/} ;;
    *) working=$(abbreviate_home "$current_dir") ;;
  esac
  left="${left} ${dim}${arrow}${reset} ${cyan}${working}${reset}"
  left_plain="${left_plain} x ${working}"
fi

path=$(abbreviate_home "$current_dir")
left="${left} ${dim}${bar}${reset} ${blue}${path}${reset}"
left_plain="${left_plain} x ${path}"
branch=$(git -C "$current_dir" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null)
if [ -n "$branch" ]; then
  left="${left} ${green}(${branch})${reset}"
  left_plain="${left_plain} (${branch})"
fi

right=""
right_plain=""
if [ "$context_pct" != "-" ]; then
  right="${dim}ctx${reset} $(percent_color "$context_pct")${context_pct}%${reset}"
  right_plain="ctx ${context_pct}%"
fi
if [ "$five_hour_pct" != "-" ]; then
  right="${right}  ${dim}5h${reset} $(percent_color "$five_hour_pct")${five_hour_pct}%${reset}"
  right_plain="${right_plain}  5h ${five_hour_pct}%"
fi
if [ "$added" -gt 0 ] || [ "$removed" -gt 0 ]; then
  right="${right}  ${green}+${added}${reset} ${red}-${removed}${reset}"
  right_plain="${right_plain}  +${added} -${removed}"
fi

# A small margin from the edge, since Claude Code indents the row slightly.
padding=$(( ${COLUMNS:-80} - 4 - ${#left_plain} - ${#right_plain} ))
[ "$padding" -lt 2 ] && padding=2
printf '%s%*s%s' "$left" "$padding" "" "$right"
exit 0
