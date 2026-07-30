#!/bin/bash
# Supervise quickshell: raise the FD ceiling, restart it when it dies, keep runtime logs bounded.
# qs does not segfault — it runs out of file descriptors and silently vanishes, taking the
# crash reporter down with it. See QS_KNOWLEDGE.md and quickshell-mirror/quickshell#723.
# Wired up from hyprland.conf as `exec-once`.

CFG_DIR="$HOME/.config/quickshell"
RUNTIME="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
QS_RUN="$RUNTIME/quickshell"
LOG="$RUNTIME/qs-supervise.log"
STOP="$RUNTIME/qs-supervise.stop"

# Raise the soft limit to the hard ceiling (1024 -> 524288). No privileges needed.
ulimit -n "$(ulimit -Hn)" 2>/dev/null

log() { printf '%s %s\n' "$(date -Is)" "$*" >> "$LOG"; }

# qs never removes its per-instance runtime dirs — a 6-day session left 70MB behind.
# Without this, a restart loop slowly fills the /run/user tmpfs.
prune_stale() {
    [ -d "$QS_RUN/by-pid" ] || return 0
    local link pid target
    for link in "$QS_RUN"/by-pid/*; do
        [ -L "$link" ] || continue
        pid=${link##*/}
        case $pid in *[!0-9]* | '') continue ;; esac
        [ -d "/proc/$pid" ] && continue

        target=$(readlink -f "$link" 2>/dev/null)
        # only ever delete inside the quickshell runtime dir
        case $target in
            "$QS_RUN"/by-id/*) rm -rf -- "$target" ;;
        esac
        rm -f -- "$link"
    done
}

rm -f "$STOP"
log "supervisor started (nofile soft=$(ulimit -Sn) hard=$(ulimit -Hn))"

# One FD sampler per session.
if [ -x "$CFG_DIR/scripts/qs-fdwatch.sh" ] && ! pgrep -f 'qs-fdwatch\.sh' >/dev/null 2>&1; then
    "$CFG_DIR/scripts/qs-fdwatch.sh" &
    log "started qs-fdwatch.sh (pid $!)"
fi

while :; do
    prune_stale

    log "starting qs"
    qs
    code=$?
    log "qs exited code=$code"

    # `touch $STOP` to end supervision deliberately
    if [ -e "$STOP" ]; then
        log "stop flag present, supervisor exiting"
        rm -f "$STOP"
        break
    fi

    sleep 2
done
