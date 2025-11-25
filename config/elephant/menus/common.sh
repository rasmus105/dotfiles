function menu() {
    prompt=$1
    options=$2

    echo -e "$options" | walker --dmenu -p "$prompt"
}
function menu_input() {
    prompt=$1

    echo "" | walker --inputonly --height 1 --dmenu -p "$prompt"
}
