#!/usr/bin/env bash

if [ -z "$1" ]; then
  echo "Usage: $0 path/to/keystore.jks [out.b64]"
  exit 2
fi
KS="$1"
OUT="${2:-}")
if [ ! -f "$KS" ]; then
  echo "File not found: $KS"
  exit 1
fi

if base64 --help 2>&1 | grep -q -- '--wrap'; then
  if [ -n "$OUT" ]; then
    base64 --wrap=0 "$KS" > "$OUT"
    echo "Wrote base64 to $OUT"
  else
    base64 --wrap=0 "$KS"
  fi
elif command -v base64 >/dev/null 2>&1; then
  if [ -n "$OUT" ]; then
    base64 "$KS" > "$OUT"
    echo "Wrote base64 to $OUT"
  else
    base64 "$KS"
  fi
else
  if command -v openssl >/dev/null 2>&1; then
    if [ -n "$OUT" ]; then
      openssl base64 -in "$KS" -out "$OUT"
      echo "Wrote base64 to $OUT"
    else
      openssl base64 -in "$KS"
    fi
  else
    echo "No base64 or openssl utility available"
    exit 3
  fi
fi
