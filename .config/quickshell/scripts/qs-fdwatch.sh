#!/bin/bash
# Sample quickshell's file-descriptor usage on an interval.
# qs dies by exhausting FDs, not by crashing — this records what leaks and how fast.
# See QS_KNOWLEDGE.md and https://github.com/quickshell-mirror/quickshell/issues/723
# Started automatically by qs-supervise.sh; safe to run standalone.

OUT="${XDG_RUNTIME_DIR:-/tmp}/qs-fdwatch.log"
INTERVAL="${1:-300}"

# The binary is /usr/bin/quickshell and `qs` is a symlink to it, so comm may be either.
qs_pid() {
    local p
    p=$(pgrep -x quickshell 2>/dev/null | head -1)
    [ -z "$p" ] && p=$(pgrep -x qs 2>/dev/null | head -1)
    printf '%s' "$p"
}

while :; do
    pid=$(qs_pid)

    if [ -n "$pid" ] && [ -d "/proc/$pid/fd" ]; then
        total=$(find "/proc/$pid/fd" -mindepth 1 -maxdepth 1 2>/dev/null | wc -l)

        # soft/hard ceiling — decides whether qs inherited Hyprland's raised limit
        limit=$(awk '/Max open files/{print $4"/"$5}' "/proc/$pid/limits" 2>/dev/null)

        # FD type histogram; strip the varying inode numbers so types collapse together
        hist=$(for f in "/proc/$pid/fd"/*; do readlink "$f" 2>/dev/null; done \
               | sed -E 's/\[[0-9]+\]/[]/' \
               | sort | uniq -c | sort -rn | head -8 \
               | awk '{printf "%s=%s ", $2, $1}')

        printf '%s pid=%s total=%s limit=%s %s\n' \
            "$(date -Is)" "$pid" "$total" "$limit" "$hist" >> "$OUT"
    fi

    sleep "$INTERVAL"
done
