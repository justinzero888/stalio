#!/bin/bash
set -e

echo "=== Stalio pre-commit check ==="

# Static analysis
echo "→ flutter analyze --no-pub"
flutter analyze --no-pub || { echo "FAIL: analysis"; exit 1; }

# Unit tests
echo "→ flutter test"
flutter test || { echo "FAIL: tests"; exit 1; }

# Secret scan
if git diff --cached | grep -qE 'sk-[or]-[a-zA-Z0-9]{20,}'; then
  echo "FAIL: API key detected in staged changes"
  exit 1
fi

echo "PASS: all checks"
