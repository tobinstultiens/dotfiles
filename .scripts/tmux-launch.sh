#!/bin/bash

# Start TMUX first; try to reattach a session
if [[ -z "$TMUX" ]]; then
  ATTACH_OPT=$(tmux ls | grep -vq attached && echo "attach")
  tmux "$ATTACH_OPT"
fi
