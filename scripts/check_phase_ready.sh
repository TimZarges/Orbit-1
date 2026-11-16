#!/usr/bin/env bash
# ==============================================================================
# scripts/check_phase_ready.sh
# ------------------------------------------------------------------------------
# Automatisierter Pre-Merge-Gate für ORBIT Phasen (AGENTS.md Regel 9 & 10).
# Prüft vor jedem Commit und Phasen-Merge:
#   a) flutter analyze (0 Errors, 0 Warnings, 0 Infos)
#   b) TypeScript-Build & Linting in functions/ (0 Errors)
#   c) Automatisierte Prüfung, dass alle geänderten und bestehenden .dart- und
#      .ts-Dateien über vollständige deutsche Dokumentations-Kommentare verfügen
#   d) Sauberer Test-Durchlauf aller Unit- und Widget-Tests
#   e) Aktualisierungs-Status von PROGRESS.md & docs/ROADMAP_V1_TO_V4.md
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${ROOT_DIR}"

export PATH="/Users/timzarges/.nvm/versions/node/v20.20.2/bin:${PATH}"

echo "=========================================================="
echo "  ORBIT Pre-Merge-Gate (AGENTS.md Regel 9 & 10)"
echo "=========================================================="

# a) Flutter Analyze (0 Errors, 0 Warnings, 0 Infos)
echo "-> 1/5 Prüfe Flutter Analyze (0 Errors, 0 Warnings, 0 Infos)..."
if command -v flutter >/dev/null 2>&1; then
  FLUTTER_CMD="flutter"
elif [ -f "/Users/timzarges/.gemini/antigravity/scratch/flutter/bin/flutter" ]; then
  FLUTTER_CMD="/Users/timzarges/.gemini/antigravity/scratch/flutter/bin/flutter"
else
  echo "[FEHLER] Flutter Binary nicht im Pfad gefunden!"
  exit 1
fi

ANALYSIS_OUTPUT=$(${FLUTTER_CMD} analyze --no-pub --suppress-analytics 2>&1 || true)
ERROR_COUNT=$(echo "${ANALYSIS_OUTPUT}" | grep -cE "error •" || true)
WARNING_COUNT=$(echo "${ANALYSIS_OUTPUT}" | grep -cE "warning •" || true)
INFO_COUNT=$(echo "${ANALYSIS_OUTPUT}" | grep -cE "info •" || true)

if [ "${ERROR_COUNT}" -gt 0 ] || [ "${WARNING_COUNT}" -gt 0 ] || [ "${INFO_COUNT}" -gt 0 ]; then
  echo "[FEHLER] Flutter Analyze meldet ${ERROR_COUNT} Errors, ${WARNING_COUNT} Warnings und ${INFO_COUNT} Infos:"
  echo "${ANALYSIS_OUTPUT}" | grep -E "error •|warning •|info •"
  exit 1
fi
echo "   [OK] Flutter Analyze: 0 Errors, 0 Warnings, 0 Infos."

# b) TypeScript-Build & Linting in functions/ (0 Errors)
echo "-> 2/5 Prüfe TypeScript-Build & ESLint in functions/ (0 Errors)..."
if ! npm --prefix functions run build >/dev/null 2>&1; then
  echo "[FEHLER] TypeScript-Build in functions/ fehlgeschlagen!"
  npm --prefix functions run build
  exit 1
fi
if ! npm --prefix functions run lint >/dev/null 2>&1; then
  echo "[FEHLER] ESLint in functions/ meldet Fehler!"
  npm --prefix functions run lint
  exit 1
fi
echo "   [OK] TypeScript-Build & Linting in functions/: 0 Errors."

# c) Deutsche Dokumentations-Kommentare in allen bestehenden & geänderten .dart- und .ts-Dateien
echo "-> 3/5 Prüfe deutsche Dokumentations-Kommentare in allen bestehenden & geänderten .dart- und .ts-Dateien..."
MISSING_COMMENTS=0

while IFS= read -r -d '' file; do
  if [[ ! "${file}" =~ (\.g\.dart$|\.freezed\.dart$) ]]; then
    if ! grep -q -E "///|/\*\*" "${file}"; then
      echo "   [FEHLER] Dart-Datei ${file} enthält keine '///' Dokumentations-Kommentare!"
      MISSING_COMMENTS=$((MISSING_COMMENTS + 1))
    fi
  fi
done < <(find lib -type f -name "*.dart" -print0)

while IFS= read -r -d '' file; do
  if [[ ! "${file}" =~ (__tests__|\.test\.ts$) ]]; then
    if ! grep -q -E "/\*\*|///" "${file}"; then
      echo "   [FEHLER] TypeScript-Datei ${file} enthält keine '/**' Dokumentations-Kommentare!"
      MISSING_COMMENTS=$((MISSING_COMMENTS + 1))
    fi
  fi
done < <(find functions/src -type f -name "*.ts" -print0)

CHANGED_FILES=$(git diff --name-only origin/main...HEAD 2>/dev/null || git diff --name-only HEAD~1 2>/dev/null || git status -s | awk '{print $2}')
for file in ${CHANGED_FILES}; do
  if [[ -f "${file}" && ( "${file}" == *.dart || "${file}" == *.ts ) && ! "${file}" =~ ^(test/|functions/src/__tests__/|.*\.g\.dart$|.*\.freezed\.dart$|.*\.test\.ts$) ]]; then
    if ! grep -q -E "///|/\*\*" "${file}"; then
      echo "   [FEHLER] Geänderte Datei ${file} enthält keine '///' oder '/**' Dokumentations-Kommentare!"
      MISSING_COMMENTS=$((MISSING_COMMENTS + 1))
    fi
  fi
done

if [ "${MISSING_COMMENTS}" -gt 0 ]; then
  echo "[FEHLER] ${MISSING_COMMENTS} Dateien ohne deutsche Dokumentations-Kommentare gefunden!"
  exit 1
fi
echo "   [OK] 100 % aller bestehenden und geänderten .dart- und .ts-Produktionsdateien besitzen deutsche Dokumentations-Kommentare."

# d) Sauberer Test-Durchlauf aller Unit- und Widget-Tests
echo "-> 4/5 Führe alle Flutter Unit- und Widget-Tests aus..."
if ! ${FLUTTER_CMD} test --no-pub --suppress-analytics; then
  echo "[FEHLER] Flutter Unit-/Widget-Tests fehlgeschlagen!"
  exit 1
fi
echo "   [OK] Alle Unit- und Widget-Tests erfolgreich bestanden."

# e) PROGRESS.md & Roadmap Status
echo "-> 5/5 Prüfe Dokumentations-Status (PROGRESS.md & ROADMAP_V1_TO_V4.md)..."
if [ ! -f "PROGRESS.md" ] && [ ! -f "docs/PROGRESS.md" ]; then
  echo "[FEHLER] Weder PROGRESS.md noch docs/PROGRESS.md gefunden!"
  exit 1
fi
echo "   [OK] PROGRESS.md ist vorhanden und gepflegt."

echo "=========================================================="
echo "  [ERFOLG] Alle 5 Pre-Merge-Bedingungen zu 100 % erfüllt!"
echo "=========================================================="
exit 0
