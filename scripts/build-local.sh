#!/bin/sh
# Build and run `fe` with plain swiftc, for machines with only the Command Line Tools
# (old SwiftPM there refuses to build without XCTest). With Xcode, use `swift run fe`.
set -e
cd "$(dirname "$0")/.."
B=${BUILD_DIR:-.build/local}
mkdir -p "$B"
swiftc -O -parse-as-library -emit-library -static -module-name FrameExact \
  -emit-module-path "$B/FrameExact.swiftmodule" -o "$B/libFrameExact.a" Sources/FrameExact/*.swift
swiftc -O -parse-as-library -emit-library -static -module-name FrameExactChecks -I "$B" \
  -emit-module-path "$B/FrameExactChecks.swiftmodule" -o "$B/libFrameExactChecks.a" Sources/FrameExactChecks/*.swift
swiftc -O -I "$B" -L "$B" -lFrameExact -lFrameExactChecks -o "$B/fe" Sources/fe/main.swift
exec "$B/fe" "$@"
