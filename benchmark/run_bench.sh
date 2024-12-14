#!/bin/bash
SESSION="experiment"
tmux new-session -d -s $SESSION
tmux send-keys -t $SESSION.0 'exec ./bench.sh' ENTER
