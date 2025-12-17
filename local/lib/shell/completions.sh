#!/usr/bin/env bash
# Shell completion generator library
# Generates completions for zsh, bash, and fish from a data-driven command definition
#
# Usage in scripts:
#   1. Define commands as associative arrays (see examples below)
#   2. Source this file
#   3. Call: handle_completions "$@" && exit 0 || exit 1
#
# Example command definitions:
#
#   # Top-level commands
#   declare -gA COMMANDS=(
#     [update]="Full system update"
#     [set]="Set theme"
#     [background]="Manage backgrounds"
#     [help]="Show this help"
#   )
#
#   # Subcommands (second level)
#   declare -gA SUBCOMMANDS_background=(
#     [set]="Set specific background"
#     [shuffle]="Set random background"
#   )
#
#   # Argument completions (any level)
#   # Format: "type:value" where type is 'files', 'function', or 'values'
#   declare -gA COMPLETIONS=(
#     [set]="function:_complete_themes"           # 'set' takes theme names
#     [background_set]="files:*.{png,jpg,jpeg}"   # 'background set' takes image files
#     [font_set]="function:_complete_fonts"       # 'font set' takes font names
#   )

#──────────────────────────────────────────────────────────────────────────────
# Completion File Generation
#──────────────────────────────────────────────────────────────────────────────

# Standard completion directories
COMP_DIR_ZSH="$HOME/.local/share/zsh/site-functions"
COMP_DIR_BASH="$HOME/.local/share/bash-completion/completions"
COMP_DIR_FISH="$HOME/.config/fish/completions"

# Generate completions for a single script and save to disk
# Usage: generate_script_completions <script_path>
generate_script_completions() {
    local script="$1"
    local name
    name=$(basename "$script")

    # Normalize name: replace hyphens with underscores for consistent filenames
    # This ensures zsh autoloading works (function name must match filename)
    local normalized_name="${name//-/_}"

    # Ensure script exists and is executable
    if [[ ! -x "$script" ]]; then
        echo "Warning: Script not found or not executable: $script" >&2
        return 1
    fi

    # Check if script supports --completions
    if ! "$script" --completions zsh &>/dev/null; then
        echo "Warning: Script does not support --completions: $script" >&2
        return 1
    fi

    # Generate for each shell (using normalized names)
    "$script" --completions zsh > "${COMP_DIR_ZSH}/_${normalized_name}"
    "$script" --completions bash > "${COMP_DIR_BASH}/${normalized_name}"
    "$script" --completions fish > "${COMP_DIR_FISH}/${normalized_name}.fish"

    echo "Generated completions for $name -> $normalized_name"
}

# Generate completions for all dotfiles scripts
# Usage: generate_all_completions
generate_all_completions() {
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/bin"

    # Create directories if they don't exist
    mkdir -p "$COMP_DIR_ZSH" "$COMP_DIR_BASH" "$COMP_DIR_FISH"

    # Scripts that support completions
    local -a scripts=(
        "$script_dir/dotfiles"
        "$script_dir/system-theme"
        "$script_dir/system-setup"
        "$script_dir/system-refresh"
    )

    local failed=0
    for script in "${scripts[@]}"; do
        if ! generate_script_completions "$script"; then
            failed=$((failed + 1))
        fi
    done

    if [[ $failed -gt 0 ]]; then
        echo "Warning: $failed script(s) failed to generate completions" >&2
        return 1
    fi

    echo "All completions generated successfully"
}

#──────────────────────────────────────────────────────────────────────────────
# Main Entry Point
#──────────────────────────────────────────────────────────────────────────────

# Call this at the start of parse_args to handle --completions
# Returns 0 if completions were handled (caller should exit 0)
# Returns 1 if not a completions request OR if it failed (caller should check)
handle_completions() {
    [[ "${1:-}" == "--completions" ]] || return 1
    local shell="${2:-}"
    local script_name
    script_name=$(basename "$0")

    case "$shell" in
    zsh) _generate_zsh_completions "$script_name" ;;
    bash) _generate_bash_completions "$script_name" ;;
    fish) _generate_fish_completions "$script_name" ;;
    *)
        echo "Usage: $script_name --completions <shell>" >&2
        echo "Supported shells: zsh, bash, fish" >&2
        return 1
        ;;
    esac
    return 0
}

#──────────────────────────────────────────────────────────────────────────────
# Helper Functions
#──────────────────────────────────────────────────────────────────────────────

# Get completion spec for a command path (e.g., "background_set")
# Returns empty string if no completion defined
_get_completion_spec() {
    local path="$1"
    declare -p COMPLETIONS &>/dev/null || return
    echo "${COMPLETIONS[$path]:-}"
}

# Check if a command has subcommands
_has_subcommands() {
    local cmd="$1"
    declare -p "SUBCOMMANDS_${cmd}" &>/dev/null
}

# Get list of subcommand parent names
_get_subcommand_parents() {
    compgen -A variable | grep '^SUBCOMMANDS_' | sed 's/^SUBCOMMANDS_//'
}

# Get command aliases (e.g., bg -> background)
_get_aliases() {
    local cmd="$1"
    case "$cmd" in
    background) echo "background|bg" ;;
    *) echo "$cmd" ;;
    esac
}

#──────────────────────────────────────────────────────────────────────────────
# ZSH Completion Generator
#──────────────────────────────────────────────────────────────────────────────

_generate_zsh_completions() {
    local script_name="$1"
    local func_name="_${script_name//-/_}"

    # Collect subcommand parents
    local -a subcommand_parents=()
    while IFS= read -r parent; do
        [[ -n "$parent" ]] && subcommand_parents+=("$parent")
    done < <(_get_subcommand_parents)

    # Output header
    cat <<EOF
#compdef $script_name
$func_name() {
    local context state state_descr line
    typeset -A opt_args

EOF

    # Build main commands array
    echo "    local -a commands=("
    for cmd in "${!COMMANDS[@]}"; do
        local desc="${COMMANDS[$cmd]}"
        desc="${desc//\'/\'\\\'\'}"
        echo "        '$cmd:$desc'"
    done
    echo "    )"
    echo

    # Generate completion logic
    cat <<'EOF'
    _arguments -C \
        '1:command:->cmd' \
        '*::arg:->args'

    case $state in
        cmd)
            _describe 'command' commands
            ;;
        args)
            case $words[1] in
EOF

    # Generate cases for each command
    for cmd in "${!COMMANDS[@]}"; do
        local aliases
        aliases=$(_get_aliases "$cmd")
        
        if _has_subcommands "$cmd"; then
            # Command has subcommands - generate nested completion
            _zsh_generate_subcommand_case "$script_name" "$cmd" "$aliases"
        else
            # Check for direct completion on this command
            local spec
            spec=$(_get_completion_spec "$cmd")
            if [[ -n "$spec" ]]; then
                _zsh_generate_completion_case "$script_name" "$cmd" "$aliases" "$spec"
            fi
        fi
    done

    # Close the case statement
    cat <<'EOF'
            esac
            ;;
    esac
}
EOF
    echo "compdef $func_name $script_name"
}

# Generate zsh case for a command with subcommands
_zsh_generate_subcommand_case() {
    local script_name="$1"
    local cmd="$2"
    local aliases="$3"

    local varname="SUBCOMMANDS_${cmd}"
    declare -n subcmds="$varname"

    echo "                $aliases)"
    echo "                    local -a subcmds=("
    for subcmd in "${!subcmds[@]}"; do
        local subdesc="${subcmds[$subcmd]}"
        subdesc="${subdesc//\'/\'\\\'\'}"
        echo "                        '$subcmd:$subdesc'"
    done
    echo "                    )"

    # Check if any subcommands have completions
    local has_subcmd_completions=false
    for subcmd in "${!subcmds[@]}"; do
        local spec
        spec=$(_get_completion_spec "${cmd}_${subcmd}")
        if [[ -n "$spec" ]]; then
            has_subcmd_completions=true
            break
        fi
    done

    if [[ "$has_subcmd_completions" == true ]]; then
        cat <<'EOF'
                    _arguments -C \
                        '1:subcommand:->subcmd' \
                        '*::subarg:->subargs'
                    case $state in
                        subcmd)
                            _describe 'subcommand' subcmds
                            ;;
                        subargs)
                            case $words[1] in
EOF
        for subcmd in "${!subcmds[@]}"; do
            local spec
            spec=$(_get_completion_spec "${cmd}_${subcmd}")
            if [[ -n "$spec" ]]; then
                echo "                                $subcmd)"
                _zsh_generate_arg_completion "$script_name" "$subcmd" "$spec" "                                    "
            fi
        done
        cat <<'EOF'
                            esac
                            ;;
                    esac
EOF
    else
        echo "                    _describe 'subcommand' subcmds"
    fi
    echo "                    ;;"
}

# Generate zsh case for a command with direct completion (no subcommands)
_zsh_generate_completion_case() {
    local script_name="$1"
    local cmd="$2"
    local aliases="$3"
    local spec="$4"

    echo "                $aliases)"
    _zsh_generate_arg_completion "$script_name" "$cmd" "$spec" "                    "
}

# Generate zsh completion for arguments based on spec
_zsh_generate_arg_completion() {
    local script_name="$1"
    local cmd="$2"
    local spec="$3"
    local indent="$4"

    local type="${spec%%:*}"
    local value="${spec#*:}"

    case "$type" in
    files)
        echo "${indent}_files -g '$value'"
        echo "${indent};;"
        ;;
    function)
        echo "${indent}local -a options=(\$(${script_name} ${value} 2>/dev/null))"
        echo "${indent}_describe 'option' options"
        echo "${indent};;"
        ;;
    values)
        echo "${indent}local -a options=(${value//,/ })"
        echo "${indent}_describe 'option' options"
        echo "${indent};;"
        ;;
    esac
}

#──────────────────────────────────────────────────────────────────────────────
# Bash Completion Generator
#──────────────────────────────────────────────────────────────────────────────

_generate_bash_completions() {
    local script_name="$1"
    local func_name="_${script_name//-/_}"

    local cmd_list="${!COMMANDS[*]}"

    # Collect subcommand parents
    local -a subcommand_parents=()
    while IFS= read -r parent; do
        [[ -n "$parent" ]] && subcommand_parents+=("$parent")
    done < <(_get_subcommand_parents)

    cat <<EOF
$func_name() {
    local cur="\${COMP_WORDS[COMP_CWORD]}"
    local prev="\${COMP_WORDS[COMP_CWORD-1]}"
    local cmd="\${COMP_WORDS[1]}"
    local subcmd="\${COMP_WORDS[2]}"

    if [[ \$COMP_CWORD -eq 1 ]]; then
        COMPREPLY=(\$(compgen -W "$cmd_list" -- "\$cur"))
        return
    fi

    case "\$cmd" in
EOF

    # Generate cases for each command
    for cmd in "${!COMMANDS[@]}"; do
        local pattern
        pattern=$(_get_aliases "$cmd")

        if _has_subcommands "$cmd"; then
            _bash_generate_subcommand_case "$script_name" "$cmd" "$pattern"
        else
            local spec
            spec=$(_get_completion_spec "$cmd")
            if [[ -n "$spec" ]]; then
                _bash_generate_completion_case "$script_name" "$cmd" "$pattern" "$spec" 2
            fi
        fi
    done

    cat <<'EOF'
    esac
}
EOF
    echo "complete -F $func_name $script_name"
}

# Generate bash case for a command with subcommands
_bash_generate_subcommand_case() {
    local script_name="$1"
    local cmd="$2"
    local pattern="$3"

    local varname="SUBCOMMANDS_${cmd}"
    declare -n subcmds="$varname"
    local subcmd_list="${!subcmds[*]}"

    echo "        $pattern)"
    echo "            if [[ \$COMP_CWORD -eq 2 ]]; then"
    echo "                COMPREPLY=(\$(compgen -W \"$subcmd_list\" -- \"\$cur\"))"

    # Check for subcommand completions at level 3
    local has_level3=false
    for subcmd in "${!subcmds[@]}"; do
        local spec
        spec=$(_get_completion_spec "${cmd}_${subcmd}")
        if [[ -n "$spec" ]]; then
            has_level3=true
            break
        fi
    done

    if [[ "$has_level3" == true ]]; then
        echo "            elif [[ \$COMP_CWORD -eq 3 ]]; then"
        echo "                case \"\$subcmd\" in"
        for subcmd in "${!subcmds[@]}"; do
            local spec
            spec=$(_get_completion_spec "${cmd}_${subcmd}")
            if [[ -n "$spec" ]]; then
                echo "                $subcmd)"
                _bash_generate_arg_completion "$script_name" "$subcmd" "$spec"
                echo "                    ;;"
            fi
        done
        echo "                esac"
    fi

    echo "            fi"
    echo "            ;;"
}

# Generate bash case for a command with direct completion
_bash_generate_completion_case() {
    local script_name="$1"
    local cmd="$2"
    local pattern="$3"
    local spec="$4"
    local level="$5"

    echo "        $pattern)"
    echo "            if [[ \$COMP_CWORD -eq $level ]]; then"
    _bash_generate_arg_completion "$script_name" "$cmd" "$spec"
    echo "            fi"
    echo "            ;;"
}

# Generate bash completion for arguments based on spec
_bash_generate_arg_completion() {
    local script_name="$1"
    local cmd="$2"
    local spec="$3"

    local type="${spec%%:*}"
    local value="${spec#*:}"

    case "$type" in
    files)
        echo "                COMPREPLY=(\$(compgen -f -X '!$value' -- \"\$cur\"))"
        echo "                compopt -o filenames"
        ;;
    function)
        echo "                local options=\$(${script_name} ${value} 2>/dev/null)"
        echo "                COMPREPLY=(\$(compgen -W \"\$options\" -- \"\$cur\"))"
        ;;
    values)
        echo "                COMPREPLY=(\$(compgen -W \"${value//,/ }\" -- \"\$cur\"))"
        ;;
    esac
}

#──────────────────────────────────────────────────────────────────────────────
# Fish Completion Generator
#──────────────────────────────────────────────────────────────────────────────

_generate_fish_completions() {
    local script_name="$1"

    # Collect subcommand parents
    local -a subcommand_parents=()
    while IFS= read -r parent; do
        [[ -n "$parent" ]] && subcommand_parents+=("$parent")
    done < <(_get_subcommand_parents)

    # Disable file completions by default
    echo "complete -c $script_name -f"
    echo

    # Main commands
    for cmd in "${!COMMANDS[@]}"; do
        local desc="${COMMANDS[$cmd]}"
        echo "complete -c $script_name -n \"__fish_use_subcommand\" -a \"$cmd\" -d \"$desc\""
    done

    # Subcommands
    for parent in "${subcommand_parents[@]}"; do
        local varname="SUBCOMMANDS_${parent}"
        declare -n subcmds="$varname"

        echo
        echo "# Subcommands for '$parent'"
        for subcmd in "${!subcmds[@]}"; do
            local subdesc="${subcmds[$subcmd]}"
            echo "complete -c $script_name -n \"__fish_seen_subcommand_from $parent\" -a \"$subcmd\" -d \"$subdesc\""

            # Handle aliases
            if [[ "$parent" == "background" ]]; then
                echo "complete -c $script_name -n \"__fish_seen_subcommand_from bg\" -a \"$subcmd\" -d \"$subdesc\""
            fi
        done
    done

    # Argument completions from COMPLETIONS array
    if declare -p COMPLETIONS &>/dev/null; then
        echo
        echo "# Argument completions"
        for path in "${!COMPLETIONS[@]}"; do
            local spec="${COMPLETIONS[$path]}"
            _fish_generate_arg_completion "$script_name" "$path" "$spec"
        done
    fi
}

# Generate fish completion for arguments based on spec
_fish_generate_arg_completion() {
    local script_name="$1"
    local path="$2"
    local spec="$3"

    local type="${spec%%:*}"
    local value="${spec#*:}"

    # Parse path to determine condition
    # e.g., "background_set" -> parent=background, subcmd=set
    # e.g., "set" -> just cmd=set
    local condition
    if [[ "$path" == *_* ]]; then
        local parent="${path%%_*}"
        local subcmd="${path#*_}"
        condition="__fish_seen_subcommand_from $parent; and __fish_seen_subcommand_from $subcmd"
        # Also handle alias
        if [[ "$parent" == "background" ]]; then
            _fish_generate_single_arg_completion "$script_name" "__fish_seen_subcommand_from bg; and __fish_seen_subcommand_from $subcmd" "$spec"
        fi
    else
        condition="__fish_seen_subcommand_from $path"
    fi

    _fish_generate_single_arg_completion "$script_name" "$condition" "$spec"
}

_fish_generate_single_arg_completion() {
    local script_name="$1"
    local condition="$2"
    local spec="$3"

    local type="${spec%%:*}"
    local value="${spec#*:}"

    case "$type" in
    files)
        # Re-enable file completions for this specific case
        echo "complete -c $script_name -n \"$condition\" -F -a \"\" -d \"Image file\""
        ;;
    function)
        echo "complete -c $script_name -n \"$condition\" -a \"($script_name $value 2>/dev/null)\""
        ;;
    values)
        for v in ${value//,/ }; do
            echo "complete -c $script_name -n \"$condition\" -a \"$v\""
        done
        ;;
    esac
}
