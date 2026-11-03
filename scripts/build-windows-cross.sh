#!/bin/sh
set -eu
ZIG_BIN="${1:-zig}"
cd "$(dirname "$0")/.."
mkdir -p dist
"$ZIG_BIN" c++ -target x86_64-windows-gnu -std=c++17 -O2 -municode -static src/windows.cpp -lgdiplus -lcomdlg32 -ladvapi32 -lgdi32 -luser32 -Wl,--subsystem,windows -o 'dist/BK Clock.exe'
