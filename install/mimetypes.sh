#!/bin/bash

configure_mimetypes() {
    # Check if required applications are installed
    local missing_apps=()
    command -v imv &>/dev/null || missing_apps+=("imv")
    command -v zathura &>/dev/null || missing_apps+=("zathura")
    command -v mpv &>/dev/null || missing_apps+=("mpv")
    command -v nvim &>/dev/null || missing_apps+=("nvim")
    
    # Check for zen browser (via .desktop file)
    if [[ ! -f "$HOME/.local/share/applications/zen.desktop" ]] && [[ ! -f "/usr/share/applications/zen.desktop" ]]; then
        missing_apps+=("zen-browser")
    fi
    
    if [[ ${#missing_apps[@]} -gt 0 ]]; then
        gum_warning "Some applications are not installed: ${missing_apps[*]}"
        gum_info "MIME type associations will be configured, but may not work until applications are installed"
    fi
    
    # Open all images with imv
    xdg-mime default imv.desktop image/png
    xdg-mime default imv.desktop image/jpeg
    xdg-mime default imv.desktop image/gif
    xdg-mime default imv.desktop image/webp
    xdg-mime default imv.desktop image/bmp
    xdg-mime default imv.desktop image/tiff

    # Open PDFs with the Document Viewer
    xdg-mime default org.pwmt.zathura.desktop application/pdf

    # Use Chromium as the default browser
    xdg-settings set default-web-browser zen.desktop
    xdg-mime default zen.desktop x-scheme-handler/http
    xdg-mime default zen.desktop x-scheme-handler/https

    # Open video files with mpv
    xdg-mime default mpv.desktop video/mp4
    xdg-mime default mpv.desktop video/x-msvideo
    xdg-mime default mpv.desktop video/x-matroska
    xdg-mime default mpv.desktop video/x-flv
    xdg-mime default mpv.desktop video/x-ms-wmv
    xdg-mime default mpv.desktop video/mpeg
    xdg-mime default mpv.desktop video/ogg
    xdg-mime default mpv.desktop video/webm
    xdg-mime default mpv.desktop video/quicktime
    xdg-mime default mpv.desktop video/3gpp
    xdg-mime default mpv.desktop video/3gpp2
    xdg-mime default mpv.desktop video/x-ms-asf
    xdg-mime default mpv.desktop video/x-ogm+ogg
    xdg-mime default mpv.desktop video/x-theora+ogg
    xdg-mime default mpv.desktop application/ogg

    # Open text files with nvim
    xdg-mime default nvim.desktop text/plain
    xdg-mime default nvim.desktop text/english
    xdg-mime default nvim.desktop text/x-makefile
    xdg-mime default nvim.desktop text/x-c++hdr
    xdg-mime default nvim.desktop text/x-c++src
    xdg-mime default nvim.desktop text/x-chdr
    xdg-mime default nvim.desktop text/x-csrc
    xdg-mime default nvim.desktop text/x-java
    xdg-mime default nvim.desktop text/x-moc
    xdg-mime default nvim.desktop text/x-pascal
    xdg-mime default nvim.desktop text/x-tcl
    xdg-mime default nvim.desktop text/x-tex
    xdg-mime default nvim.desktop application/x-shellscript
    xdg-mime default nvim.desktop text/x-c
    xdg-mime default nvim.desktop text/x-c++
    xdg-mime default nvim.desktop application/xml
    xdg-mime default nvim.desktop text/xml
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    configure_mimetypes "$@"
fi
