#!/usr/bin/env zsh

# Man page colorization and man-page helpers.

# ==============================================================================
# Colors
# ==============================================================================

autoload -U colors && colors

typeset -AHg less_termcap
less_termcap[mb]="${fg_bold[red]}"
less_termcap[md]="${fg_bold[red]}"
less_termcap[me]="${reset_color}"
less_termcap[so]="${fg_bold[yellow]}${bg[blue]}"
less_termcap[se]="${reset_color}"
less_termcap[us]="${fg_bold[green]}"
less_termcap[ue]="${reset_color}"

typeset -g __colored_man_pages_dir="${0:A:h}"

# ==============================================================================
# Color Wrapper
# ==============================================================================

colored() {
  local -a environment
  local k v

  for k v in "${(@kv)less_termcap}"; do
    environment+=("LESS_TERMCAP_${k}=${v}")
  done

  environment+=(PAGER="${commands[less]:-$PAGER}")
  environment+=(GROFF_NO_SGR=1)

  if [[ "$OSTYPE" == solaris* ]]; then
    environment+=(PATH="${__colored_man_pages_dir}:$PATH")
  fi

  command env $environment "$@"
}

man() {
  colored man "$@"
}

dman() {
  colored dman "$@"
}

debman() {
  colored debman "$@"
}

# ==============================================================================
# Helpers
# ==============================================================================

manl() {
  local linux_man_root="$HOME/git/public/man-pages"
  MANPATH="$linux_man_root${MANPATH:+:$MANPATH}" man "$@"
}
