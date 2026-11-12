#!/usr/bin/env bash
#
# resolve-apex-tests.sh
#
# Resolves Apex test classes to run for a deployment by reading @tests
# annotations from changed Apex classes and triggers.
#
# ANNOTATION FORMAT (add to every non-test Apex class/trigger header):
#   /**
#    * @tests: MyClassTest, AnotherTest
#    */
#
# BEHAVIOR:
#   1. Reads changed .cls and .trigger files between BASE_REF and HEAD
#   2. If file is a test class (@IsTest) → runs itself
#   3. If file has @tests annotation → runs those test classes
#   4. If no annotation found → falls back to <ClassName>Test convention
#   5. Writes resolved test names (space-separated) to $OUTPUT_FILE
#
# USAGE:
#   STRICT=false SOURCE_DIR=force-app OUTPUT_FILE=apex-tests.txt \
#   bash scripts/resolve-apex-tests.sh <base-ref> [head-ref]
#
# OUTPUT:
#   apex-tests.txt — space-separated list of test class names to run.
#   Empty file means no Apex changed.
 
set -euo pipefail
 
BASE_REF="${1:-HEAD~1}"
HEAD_REF="${2:-HEAD}"
SOURCE_DIR="${SOURCE_DIR:-force-app}"
OUTPUT_FILE="${OUTPUT_FILE:-apex-tests.txt}"
STRICT="${STRICT:-false}"
 
echo "========================================"
echo "Resolve Apex Tests"
echo "Range : $BASE_REF..$HEAD_REF"
echo "Source: $SOURCE_DIR"
echo "Strict: $STRICT"
echo "========================================"
 
# Get added, modified, or renamed Apex files (ignore deletions)
# Meta-only changes map back to the source file
mapfile -t changed < <(
  git diff --name-only --diff-filter=AMR "$BASE_REF" "$HEAD_REF" -- "$SOURCE_DIR" \
    | grep -E '\.(cls|trigger)(-meta\.xml)?$' \
    | sed -E 's/-meta\.xml$//' \
    | sort -u || true
)
 
if [[ ${#changed[@]} -eq 0 ]]; then
  echo "No Apex changes detected. No tests required."
  : > "$OUTPUT_FILE"
  exit 0
fi
 
echo ""
echo "Changed Apex files:"
printf '  %s\n' "${changed[@]}"
echo ""
 
declare -A tests=()
unannotated=()
unknown=()
 
for file in "${changed[@]}"; do
  # Skip if file was deleted
  [[ -f "$file" ]] || continue
 
  name="$(basename "$file")"
  name="${name%.*}"
 
  # Test classes run themselves
  if [[ "$file" == *.cls ]] && grep -qiE '@isTest' "$file"; then
    tests["$name"]=1
    echo "  ✔ $name → runs itself (test class)"
    continue
  fi
 
  # Read @tests annotation from the file
  found="$(grep -hoiE '@tests:?[[:space:]]+[A-Za-z0-9_, ]+' "$file" \
    | sed -E 's/^@tests:?[[:space:]]+//I' \
    | tr ',' ' ' \
    | tr -s ' ' || true)"
 
  if [[ -z "${found// /}" ]]; then
    unannotated+=("$file")
    echo "  ⚠ $name → no @tests annotation found"
    continue
  fi
 
  for t in $found; do
    t="$(echo "$t" | tr -d '[:space:]')"
    [[ -z "$t" ]] && continue
 
    if [[ -z "$(find "$SOURCE_DIR" -name "$t.cls" -print -quit)" ]]; then
      unknown+=("$t (referenced in $file)")
      echo "  ✘ $t → not found in $SOURCE_DIR (referenced in $name)"
    else
      tests["$t"]=1
      echo "  ✔ $name → $t"
    fi
  done
done
 
# --------------------------------------------------------
# Handle gaps
# --------------------------------------------------------
gaps=false
 
if [[ ${#unannotated[@]} -gt 0 ]] || [[ ${#unknown[@]} -gt 0 ]]; then
  gaps=true
  echo ""
  echo "========================================"
  echo "GAPS DETECTED"
 
  if [[ ${#unannotated[@]} -gt 0 ]]; then
    echo "Missing @tests annotation:"
    printf '  %s\n' "${unannotated[@]}"
  fi
 
  if [[ ${#unknown[@]} -gt 0 ]]; then
    echo "@tests references class not found in $SOURCE_DIR:"
    printf '  %s\n' "${unknown[@]}"
  fi
  echo "========================================"
fi
 
# --------------------------------------------------------
# If strict mode and gaps found — fail the build
# --------------------------------------------------------
if [[ "$gaps" == true ]] && [[ "$STRICT" == true ]]; then
  echo ""
  echo "STRICT=true: failing build. Fix @tests annotations above before deploying."
  exit 1
fi
 
# --------------------------------------------------------
# Convention fallback for unannotated classes
# (<ClassName>Test) when STRICT=false
# --------------------------------------------------------
if [[ ${#unannotated[@]} -gt 0 ]]; then
  echo ""
  echo "Applying naming convention fallback (<ClassName>Test) for unannotated classes..."
 
  for file in "${unannotated[@]}"; do
    [[ -f "$file" ]] || continue
 
    name="$(basename "$file")"
    name="${name%.*}"
    convention="${name}Test"
 
    if [[ -n "$(find "$SOURCE_DIR" -name "$convention.cls" -print -quit)" ]]; then
      tests["$convention"]=1
      echo "  ✔ $name → $convention (convention fallback)"
    else
      echo "  ✘ $name → $convention not found either. Deploy may fail coverage check."
    fi
  done
fi
 
# --------------------------------------------------------
# Write output
# --------------------------------------------------------
if [[ ${#tests[@]} -eq 0 ]]; then
  echo ""
  echo "No tests resolved. Writing empty file."
  : > "$OUTPUT_FILE"
  exit 0
fi
 
printf '%s\n' "${!tests[@]}" | sort -u | tr '\n' ' ' | sed 's/ $//' > "$OUTPUT_FILE"
 
echo ""
echo "========================================"
echo "Tests to run: $(cat "$OUTPUT_FILE")"
echo "========================================"