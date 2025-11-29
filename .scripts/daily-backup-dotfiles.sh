#!/bin/bash

HOME=/home/tobins

GIT="/usr/bin/git --git-dir=$HOME/.cfg --work-tree=$HOME"

$GIT commit -am "auto commit"
$GIT push
