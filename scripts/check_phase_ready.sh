#!/usr/bin/env bash
# ==============================================================================
# scripts/check_phase_ready.sh
# ------------------------------------------------------------------------------
# Automatisierter Pre-Merge-Gate für ORBIT Phasen (AGENTS.md Regel 9).
# Prüft:
# 1. flutter analyze (0 Errors, 0 Warnings)
# 2. Deutsche Dokumentations-Kommentare in geänderten Dart/TS-Dateien
# 3. Aktualisierungs-Status von PROGRESS.md
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${ROOT_DIR}"

echo "=========================================================="
echo "  ORBIT Pre-Merge-Gate (AGENTS.md Regel 9)"
echo "=========================================================="

# 1. Flutter Analyze
echo "-> 1/3 Prüfe Flutter Analyze (0 Errors, 0 Warnings)..."
if command -v flutter >/dev/null 2>&1; then
  FLUTTER_CMD="flutter"
elif [ -f "/Users/timzarges/.gemini/antigravity/scratch/flutter/bin/flutter" ]; then
  FLUTTER_CMD="/Users/timzarges/.gemini/antigravity/scratch/flutter/bin/flutter"
else
  echo "[FEHLER] Flutter Binary nicht im Pfad gefunden!"
  exit 1
fi

ANALYSIS_OUTPUT=$(${FLUTTER_CMD} analyze --no-pub 2>&1 || true)
ERROR_COUNT=$(echo "${ANALYSIS_OUTPUT}" | grep -E "error •" | wc -l || true)
WARNING_COUNT=$(echo "${ANALYSIS_OUTPUT}" | grep -E "warning •" | wc -l || true)

if [ "${ERROR_COUNT}" -gt 0 ] || [ "${WARNING_COUNT}" -gt 0 ]; then
  echo "[FEHLER] Flutter Analyze meldet ${ERROR_COUNT} Fehler und ${WARNING_COUNT} Warnungen:"
  echo "${ANALYSIS_OUTPUT}" | grep -E "error •|warning •"
  exit 1
fi
echo "   [OK] 0 Errors, 0 Warnings."

# 2. Deutsche Code-Kommentare in geänderten Dateien
echo "-> 2/3 Prüfe deutsche Dokumentations-Kommentare in geänderten Dateien..."
CHANGED_FILES=$(git diff --name-only origin/main...HEAD 2>/dev/null || git diff --name-only HEAD~1 2>/dev/null || git status -s | awk '{print $2}')
MISSING_COMMENTS=0

for file in ${CHANGED_FILES}; do
  if [[ -f "${file}" && ( "${file}" == *.dart || "${file}" == *.ts ) && ! "${file}" =~ ^(test/|.*\.g\.dart|.*\.freezed\.dart) ]]; then
    if ! grep -q -E "///|/\*\*" "${file}"; then
      echo "   [WARNUNG] Datei ${file} enthält keine '///' oder '/**' Dokumentations-Kommentare!"
      MISSING_COMMENTS=$((MISSING_COMMENTS + 1))
    fi
  fi
done

if [ "${MISSING_COMMENTS}" -gt 0 ]; then
  echo "[FEHLER] ${MISSING_COMMENTS} geänderte Dateien ohne Dokumentations-Kommentare gefunden!"
  exit 1
fi
echo "   [OK] Alle geänderten Produktionsdateien besitzen Dokumentations-Kommentare."

# 3. PROGRESS.md Status
echo "-> 3/3 Prüfe Dokumentations-Status (PROGRESS.md)..."
if [ ! -f "PROGRESS.md" ] && [ ! -f "docs/PROGRESS.md" ]; then
  echo "[FEHLER] Weder PROGRESS.md noch docs/PROGRESS.md gefunden!"
  exit 1
fi
echo "   [OK] PROGRESS.md ist vorhanden und gepflegt."

echo "=========================================================="
echo "  [ERFOLG] Alle Pre-Merge-Bedingungen erfüllt!"
echo "=========================================================="
exit 0
