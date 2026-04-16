#!/bin/sh

dcgo_path=~/Games/DCGO\ Standalone

rm -rf "$dcgo_path"/Game/*

unzip "$1" "Game/*" -d "$dcgo_path"

rm -i "$1"
