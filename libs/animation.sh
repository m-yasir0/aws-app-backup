animation() {
    local text=$1
    local delay=0.1
    local spinstr='|/-\'
    echo -n "$text "
    while [ "$SPINNING" = true ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
}

start_animation() {
    local text=$1
    if [ -n "$ANIMATION_PID" ]; then
        kill $ANIMATION_PID > /dev/null 2>&1
        wait $ANIMATION_PID > /dev/null 2>&1
    fi
    SPINNING=true
    exec 3>&1
    animation $text 3>&1 &
    ANIMATION_PID=$!
}

stop_animation() {
    SPINNING=false
    if [ -n "$ANIMATION_PID" ]; then
        kill $ANIMATION_PID > /dev/null 2>&1
        wait $ANIMATION_PID > /dev/null 2>&1
    fi
    printf "\n"
}

cleanup() {
    stop_animation
    echo -e "\n\nScript interrupted. Press enter..."
    rm -rf $BACKUP_DIR
    exit 1
}

trap cleanup SIGINT SIGTERM
