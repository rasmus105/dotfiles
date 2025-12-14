#!/usr/bin/env bash
#──────────────────────────────────────────────────────────────────────────────
# Theme Generator
# Generates app-specific config files from a theme.toml definition
#──────────────────────────────────────────────────────────────────────────────
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

#──────────────────────────────────────────────────────────────────────────────
# TOML Parser (simple key-value extraction)
#──────────────────────────────────────────────────────────────────────────────

declare -A THEME

parse_toml() {
    local file="$1"
    local current_section=""
    
    while IFS= read -r line || [[ -n "$line" ]]; do
        # Skip empty lines and comments
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
        
        # Remove leading/trailing whitespace
        line="${line#"${line%%[![:space:]]*}"}"
        line="${line%"${line##*[![:space:]]}"}"
        
        # Section header [section] or [section.subsection]
        if [[ "$line" =~ ^\[([a-zA-Z0-9._-]+)\]$ ]]; then
            current_section="${BASH_REMATCH[1]}"
            continue
        fi
        
        # Key-value pair: key = "value" or key = value
        if [[ "$line" =~ ^([a-zA-Z0-9_-]+)[[:space:]]*=[[:space:]]*\"?([^\"]*)\"?$ ]]; then
            local key="${BASH_REMATCH[1]}"
            local value="${BASH_REMATCH[2]}"
            
            # Build full key path
            if [[ -n "$current_section" ]]; then
                THEME["${current_section}.${key}"]="$value"
            else
                THEME["$key"]="$value"
            fi
        fi
    done < "$file"
}

get() {
    local key="$1"
    local default="${2:-}"
    echo "${THEME[$key]:-$default}"
}

# Check if a key exists
has() {
    local key="$1"
    [[ -v "THEME[$key]" ]]
}

#──────────────────────────────────────────────────────────────────────────────
# Color Utilities
#──────────────────────────────────────────────────────────────────────────────

# Convert #RRGGBB to "R,G,B"
hex_to_rgb() {
    local hex="${1#\#}"
    printf "%d,%d,%d" "0x${hex:0:2}" "0x${hex:2:2}" "0x${hex:4:2}"
}

# Convert #RRGGBB to "rgba(R,G,B,A)"
hex_to_rgba() {
    local hex="${1#\#}"
    local alpha="${2:-1}"
    printf "rgba(%d,%d,%d,%s)" "0x${hex:0:2}" "0x${hex:2:2}" "0x${hex:4:2}" "$alpha"
}

# Strip # from hex color
strip_hash() {
    echo "${1#\#}"
}

#──────────────────────────────────────────────────────────────────────────────
# Generator Functions
#──────────────────────────────────────────────────────────────────────────────

generate_alacritty() {
    local output="$1"
    cat > "$output" << EOF
[colors.primary]
background = "$(get colors.background)"
foreground = "$(get colors.foreground)"
dim_foreground = "$(get colors.dim_foreground "$(get colors.overlay)")"
bright_foreground = "$(get colors.bright_foreground "$(get colors.foreground)")"

[colors.cursor]
text = "$(get colors.background)"
cursor = "$(get colors.cursor "$(get colors.foreground)")"

[colors.vi_mode_cursor]
text = "$(get colors.background)"
cursor = "$(get colors.accent)"

[colors.search.matches]
foreground = "$(get colors.background)"
background = "$(get colors.overlay)"

[colors.search.focused_match]
foreground = "$(get colors.background)"
background = "$(get colors.green)"

[colors.footer_bar]
foreground = "$(get colors.background)"
background = "$(get colors.overlay)"

[colors.hints.start]
foreground = "$(get colors.background)"
background = "$(get colors.yellow)"

[colors.hints.end]
foreground = "$(get colors.background)"
background = "$(get colors.overlay)"

[colors.selection]
text = "$(get colors.background)"
background = "$(get colors.selection "$(get colors.overlay)")"

[colors.normal]
black = "$(get colors.black)"
red = "$(get colors.red)"
green = "$(get colors.green)"
yellow = "$(get colors.yellow)"
blue = "$(get colors.blue)"
magenta = "$(get colors.magenta)"
cyan = "$(get colors.cyan)"
white = "$(get colors.white)"

[colors.bright]
black = "$(get colors.bright_black "$(get colors.black)")"
red = "$(get colors.bright_red "$(get colors.red)")"
green = "$(get colors.bright_green "$(get colors.green)")"
yellow = "$(get colors.bright_yellow "$(get colors.yellow)")"
blue = "$(get colors.bright_blue "$(get colors.blue)")"
magenta = "$(get colors.bright_magenta "$(get colors.magenta)")"
cyan = "$(get colors.bright_cyan "$(get colors.cyan)")"
white = "$(get colors.bright_white "$(get colors.white)")"
EOF

    # Add dim colors if any are defined
    if has colors.dim_black; then
        cat >> "$output" << EOF

[colors.dim]
black = "$(get colors.dim_black)"
red = "$(get colors.dim_red)"
green = "$(get colors.dim_green)"
yellow = "$(get colors.dim_yellow)"
blue = "$(get colors.dim_blue)"
magenta = "$(get colors.dim_magenta)"
cyan = "$(get colors.dim_cyan)"
white = "$(get colors.dim_white)"
EOF
    fi

    # Add indexed colors if defined
    if has colors.orange; then
        cat >> "$output" << EOF

[[colors.indexed_colors]]
index = 16
color = "$(get colors.orange)"
EOF
    fi

    if has colors.extra; then
        cat >> "$output" << EOF

[[colors.indexed_colors]]
index = 17
color = "$(get colors.extra)"
EOF
    fi
}

generate_ghostty() {
    local output="$1"
    
    if has apps.ghostty; then
        echo "theme = $(get apps.ghostty)" > "$output"
    else
        # Generate from colors
        cat > "$output" << EOF
background = $(strip_hash "$(get colors.background)")
foreground = $(strip_hash "$(get colors.foreground)")
cursor-color = $(strip_hash "$(get colors.cursor "$(get colors.foreground)")")
selection-background = $(strip_hash "$(get colors.selection "$(get colors.overlay)")")
selection-foreground = $(strip_hash "$(get colors.foreground)")

palette = 0=$(strip_hash "$(get colors.black)")
palette = 1=$(strip_hash "$(get colors.red)")
palette = 2=$(strip_hash "$(get colors.green)")
palette = 3=$(strip_hash "$(get colors.yellow)")
palette = 4=$(strip_hash "$(get colors.blue)")
palette = 5=$(strip_hash "$(get colors.magenta)")
palette = 6=$(strip_hash "$(get colors.cyan)")
palette = 7=$(strip_hash "$(get colors.white)")
palette = 8=$(strip_hash "$(get colors.bright_black "$(get colors.black)")")
palette = 9=$(strip_hash "$(get colors.bright_red "$(get colors.red)")")
palette = 10=$(strip_hash "$(get colors.bright_green "$(get colors.green)")")
palette = 11=$(strip_hash "$(get colors.bright_yellow "$(get colors.yellow)")")
palette = 12=$(strip_hash "$(get colors.bright_blue "$(get colors.blue)")")
palette = 13=$(strip_hash "$(get colors.bright_magenta "$(get colors.magenta)")")
palette = 14=$(strip_hash "$(get colors.bright_cyan "$(get colors.cyan)")")
palette = 15=$(strip_hash "$(get colors.bright_white "$(get colors.white)")")
EOF
    fi
}

generate_neovim() {
    local output="$1"
    
    if ! has apps.neovim; then
        echo "Error: apps.neovim is required (neovim colorscheme name)" >&2
        return 1
    fi
    
    cat > "$output" << EOF
return {
	colorscheme = "$(get apps.neovim)",
}
EOF
}

generate_waybar() {
    local output="$1"
    local fg bg overlay accent red yellow green
    fg=$(get colors.foreground)
    bg=$(get colors.surface "$(get colors.background)")
    overlay=$(get colors.overlay "$(get colors.surface "$(get colors.background)")")
    accent=$(get colors.accent)
    red=$(get colors.red)
    yellow=$(get colors.yellow)
    green=$(get colors.green)
    
    cat > "$output" << EOF
/* Theme colors - imported by style.css */
@define-color foreground $fg;
@define-color background $bg;

/* Derived colors for waybar UI */
@define-color bg-base rgba(0, 0, 0, 0.00);
@define-color fg-primary $fg;
@define-color fg-secondary $(hex_to_rgba "$fg" 0.6);
@define-color fg-muted $(hex_to_rgba "$fg" 0.4);
@define-color hover-overlay $(hex_to_rgba "$fg" 0.1);
@define-color warning-color $yellow;
@define-color critical-color $red;
@define-color success-color $green;
EOF
}

generate_walker() {
    local output="$1"
    local surface
    surface=$(get colors.surface_alt "$(get colors.surface "$(get colors.background)")")
    cat > "$output" << EOF
@define-color selected-text $(get colors.accent);
@define-color text $(get colors.foreground);
@define-color base $surface;
@define-color border $(get colors.border "$(get colors.foreground)");
@define-color foreground $(get colors.foreground);
@define-color background $surface;
EOF
}

generate_swayosd() {
    local output="$1"
    local surface
    surface=$(get colors.surface_alt "$(get colors.surface "$(get colors.background)")")
    cat > "$output" << EOF
@define-color background-color $surface;
@define-color border-color $(get colors.border "$(get colors.foreground)");
@define-color label $(get colors.foreground);
@define-color image $(get colors.foreground);
@define-color progress $(get colors.foreground);
EOF
}

generate_hyprland() {
    local output="$1"
    local border_color
    border_color=$(strip_hash "$(get colors.border "$(get colors.foreground)")")
    
    cat > "$output" << EOF
\$activeBorderColor = rgb($border_color)

general {
    col.active_border = \$activeBorderColor
}

group {
    col.border_active = \$activeBorderColor
}
EOF
}

generate_hyprlock() {
    local output="$1"
    local bg fg accent
    bg=$(get colors.background)
    fg=$(get colors.foreground)
    accent=$(get colors.accent)
    
    cat > "$output" << EOF
\$color = $(hex_to_rgba "$bg" 1.0)
\$inner_color = $(hex_to_rgba "$bg" 0.8)
\$outer_color = $(hex_to_rgba "$fg" 1.0)
\$font_color = $(hex_to_rgba "$fg" 1.0)
\$check_color = $(hex_to_rgba "$accent" 1.0)
EOF
}

generate_mako() {
    local output="$1"
    local bg fg border
    bg=$(strip_hash "$(get colors.surface_alt "$(get colors.surface "$(get colors.background)")")")
    fg=$(strip_hash "$(get colors.foreground)")
    border=$(strip_hash "$(get colors.border "$(get colors.accent)")")
    
    cat > "$output" << EOF
text-color=#$fg
border-color=#$border
background-color=#${bg}95
EOF
}

generate_zathura() {
    local output="$1"
    local bg fg surface overlay red yellow accent
    bg=$(get colors.background)
    fg=$(get colors.foreground)
    surface=$(get colors.surface "$bg")
    overlay=$(get colors.overlay "$surface")
    red=$(get colors.red)
    yellow=$(get colors.yellow)
    accent=$(get colors.accent)
    
    cat > "$output" << EOF
set default-fg                $(hex_to_rgba "$fg" 1)
set default-bg                $(hex_to_rgba "$bg" 0.8)

set completion-bg             $(hex_to_rgba "$surface" 1)
set completion-fg             $(hex_to_rgba "$fg" 1)
set completion-highlight-bg   $(hex_to_rgba "$accent" 1)
set completion-highlight-fg   $(hex_to_rgba "$bg" 1)
set completion-group-bg       $(hex_to_rgba "$bg" 1)
set completion-group-fg       $(hex_to_rgba "$fg" 1)

set statusbar-fg              $(hex_to_rgba "$fg" 1)
set statusbar-bg              $(hex_to_rgba "$bg" 1)
set inputbar-fg               $(hex_to_rgba "$fg" 1)
set inputbar-bg               $(hex_to_rgba "$bg" 1)

set notification-bg           $(hex_to_rgba "$bg" 1)
set notification-fg           $(hex_to_rgba "$fg" 1)
set notification-error-bg     $(hex_to_rgba "$bg" 1)
set notification-error-fg     $(hex_to_rgba "$red" 1)
set notification-warning-bg   $(hex_to_rgba "$bg" 1)
set notification-warning-fg   $(hex_to_rgba "$yellow" 1)

set recolor-lightcolor        $(hex_to_rgba "$bg" 1)
set recolor-darkcolor         $(hex_to_rgba "$fg" 1)

set index-fg                  $(hex_to_rgba "$fg" 1)
set index-bg                  $(hex_to_rgba "$bg" 1)
set index-active-fg           $(hex_to_rgba "$fg" 1)
set index-active-bg           $(hex_to_rgba "$surface" 1)

set render-loading-bg         $(hex_to_rgba "$bg" 1)
set render-loading-fg         $(hex_to_rgba "$fg" 1)

set highlight-color           $(hex_to_rgba "$overlay" 0.3)
set highlight-fg              $(hex_to_rgba "$fg" 1)
set highlight-active-color    $(hex_to_rgba "$accent" 0.3)
EOF
}

generate_btop() {
    local output="$1"
    local bg fg surface overlay accent
    local red green yellow blue magenta cyan
    local title highlight
    
    bg=$(get colors.background)
    fg=$(get colors.foreground)
    surface=$(get colors.surface "$bg")
    overlay=$(get colors.overlay "$surface")
    accent=$(get colors.accent)
    
    red=$(get colors.red)
    green=$(get colors.green)
    yellow=$(get colors.yellow)
    blue=$(get colors.blue)
    magenta=$(get colors.magenta)
    cyan=$(get colors.cyan)
    
    # Btop-specific colors with fallbacks
    title=$(get colors.btop_title "$fg")
    highlight=$(get colors.btop_highlight "$accent")
    
    cat > "$output" << EOF
# Main background, empty for terminal default, need to be empty if you want transparent background
theme[main_bg]="$bg"

# Main text color
theme[main_fg]="$fg"

# Title color for boxes
theme[title]="$title"

# Highlight color for keyboard shortcuts
theme[hi_fg]="$highlight"

# Background color of selected item in processes box
theme[selected_bg]="$overlay"

# Foreground color of selected item in processes box
theme[selected_fg]="$accent"

# Color of inactive/disabled text
theme[inactive_fg]="$overlay"

# Color of text appearing on top of graphs, i.e uptime and current network graph scaling
theme[graph_text]="$fg"

# Background color of the percentage meters
theme[meter_bg]="$overlay"

# Misc colors for processes box including mini cpu graphs, details memory graph and details status text
theme[proc_misc]="$accent"

# CPU, Memory, Network, Proc box outline colors
theme[cpu_box]="$(get colors.btop_cpu_box "$magenta")"
theme[mem_box]="$(get colors.btop_mem_box "$green")"
theme[net_box]="$(get colors.btop_net_box "$red")"
theme[proc_box]="$(get colors.btop_proc_box "$blue")"

# Box divider line and small boxes line color
theme[div_line]="$overlay"

# Temperature graph color (Green -> Yellow -> Red)
theme[temp_start]="$green"
theme[temp_mid]="$yellow"
theme[temp_end]="$red"

# CPU graph colors
theme[cpu_start]="$(get colors.btop_cpu_start "$cyan")"
theme[cpu_mid]="$(get colors.btop_cpu_mid "$blue")"
theme[cpu_end]="$(get colors.btop_cpu_end "$magenta")"

# Mem/Disk free meter
theme[free_start]="$magenta"
theme[free_mid]="$blue"
theme[free_end]="$cyan"

# Mem/Disk cached meter
theme[cached_start]="$cyan"
theme[cached_mid]="$blue"
theme[cached_end]="$magenta"

# Mem/Disk available meter
theme[available_start]="$(get colors.orange "$yellow")"
theme[available_mid]="$red"
theme[available_end]="$red"

# Mem/Disk used meter
theme[used_start]="$green"
theme[used_mid]="$cyan"
theme[used_end]="$blue"

# Download graph colors
theme[download_start]="$(get colors.orange "$yellow")"
theme[download_mid]="$red"
theme[download_end]="$red"

# Upload graph colors
theme[upload_start]="$green"
theme[upload_mid]="$cyan"
theme[upload_end]="$blue"

# Process box color gradient for threads, mem and cpu usage
theme[process_start]="$cyan"
theme[process_mid]="$blue"
theme[process_end]="$magenta"
EOF
}

generate_browser() {
    local output="$1"
    local bg
    bg=$(get colors.surface "$(get colors.background)")
    hex_to_rgb "$bg" > "$output"
}

generate_vscode() {
    local output="$1"
    
    if ! has apps.vscode_name || ! has apps.vscode_extension; then
        echo "Error: apps.vscode_name and apps.vscode_extension are required" >&2
        return 1
    fi
    
    cat > "$output" << EOF
{
  "name": "$(get apps.vscode_name)",
  "extension": "$(get apps.vscode_extension)"
}
EOF
}

generate_icons() {
    local output="$1"
    local icons
    icons=$(get apps.icons "Yaru-blue")
    echo "$icons" > "$output"
}

generate_lightmode() {
    local output="$1"
    local mode
    mode=$(get mode "dark")
    
    if [[ "$mode" == "light" ]]; then
        touch "$output"
    elif [[ -f "$output" ]]; then
        rm -f "$output"
    fi
}

#──────────────────────────────────────────────────────────────────────────────
# Main
#──────────────────────────────────────────────────────────────────────────────

generate_theme() {
    local theme_toml="$1"
    local output_dir="$2"
    
    if [[ ! -f "$theme_toml" ]]; then
        echo "Error: Theme file not found: $theme_toml" >&2
        return 1
    fi
    
    # Parse the theme file
    parse_toml "$theme_toml"
    
    # Validate required fields
    local required_colors=(
        "colors.background" "colors.foreground" "colors.accent"
        "colors.black" "colors.red" "colors.green" "colors.yellow"
        "colors.blue" "colors.magenta" "colors.cyan" "colors.white"
    )
    
    for key in "${required_colors[@]}"; do
        if ! has "$key"; then
            echo "Error: Missing required color: $key" >&2
            return 1
        fi
    done
    
    if ! has "apps.neovim"; then
        echo "Error: Missing required field: apps.neovim" >&2
        return 1
    fi
    
    # Create output directory
    mkdir -p "$output_dir"
    
    # Generate all config files
    echo "Generating theme configs in $output_dir..."
    
    generate_alacritty "$output_dir/alacritty.toml"
    generate_ghostty "$output_dir/ghostty.conf"
    generate_neovim "$output_dir/neovim.lua"
    generate_waybar "$output_dir/waybar.css"
    generate_walker "$output_dir/walker.css"
    generate_swayosd "$output_dir/swayosd.css"
    generate_hyprland "$output_dir/hyprland.conf"
    generate_hyprlock "$output_dir/hyprlock.conf"
    generate_mako "$output_dir/mako.ini"
    generate_zathura "$output_dir/zathura.theme"
    generate_btop "$output_dir/btop.theme"
    generate_browser "$output_dir/browser.theme"
    generate_icons "$output_dir/icons.theme"
    generate_lightmode "$output_dir/light.mode"
    
    # Generate vscode.json only if both fields are present
    if has apps.vscode_name && has apps.vscode_extension; then
        generate_vscode "$output_dir/vscode.json"
    fi
    
    echo "Theme generation complete!"
}

# Allow sourcing for testing individual functions
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [[ $# -lt 2 ]]; then
        echo "Usage: $0 <theme.toml> <output_dir>" >&2
        exit 1
    fi
    generate_theme "$1" "$2"
fi
