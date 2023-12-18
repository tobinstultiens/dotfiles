#!/bin/sh

# Start TMUX first; try to reattach a session
if [ -z "$TMUX" ]; then
  ATTACH_OPT=$(tmux ls | grep -vq attached && echo "attach -d")
  exec eval "tmux $ATTACH_OPT"
fi
