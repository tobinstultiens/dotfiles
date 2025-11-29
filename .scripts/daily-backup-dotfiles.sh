#!/bin/bash

echo "HOME is: $HOME" >> /home/tobins/git-daily-commit-log

GIT="/usr/bin/git --git-dir=/home/tobins/.cfg --work-tree=/home/tobins"

$GIT commit -am "auto commit"
$GIT push
