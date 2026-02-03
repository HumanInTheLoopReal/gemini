#!/bin/bash
# ============================================================
# VALIDATION SCRIPT - Ultra-compact output
# ============================================================
# Usage: ./scripts/validate.sh
# ============================================================

set -o pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
DIM='\033[0;90m'
NC='\033[0m'

OVERALL_EXIT=0

# ------------------------------------------------------------
# RUN ALL CHECKS IN PARALLEL
# ------------------------------------------------------------
TMPDIR=$(mktemp -d)
trap "rm -rf $TMPDIR" EXIT

npm run test > "$TMPDIR/test" 2>&1 &
TEST_PID=$!

npm run lint > "$TMPDIR/lint" 2>&1 &
LINT_PID=$!

npm run typecheck > "$TMPDIR/typecheck" 2>&1 &
TYPECHECK_PID=$!

# Wait for each and capture exit codes
wait $TEST_PID; TEST_EXIT=$?
wait $LINT_PID; LINT_EXIT=$?
wait $TYPECHECK_PID; TYPECHECK_EXIT=$?

# Read outputs
TEST_OUTPUT=$(cat "$TMPDIR/test")
LINT_OUTPUT=$(cat "$TMPDIR/lint")
TYPECHECK_OUTPUT=$(cat "$TMPDIR/typecheck")

# ------------------------------------------------------------
# 1. TESTS
# ------------------------------------------------------------
if [ $TEST_EXIT -eq 0 ]; then
  # Extract test counts per package from vitest output
  # Vitest shows "RUN ... /packages/cli" then later "Tests  X passed"
  CLI_COUNT=$(echo "$TEST_OUTPUT" 2>/dev/null | awk '/RUN.*\/packages\/cli$/{found=1} found && /Tests.*passed/{match($0,/[0-9]+/); print substr($0,RSTART,RLENGTH); exit}')
  CORE_COUNT=$(echo "$TEST_OUTPUT" 2>/dev/null | awk '/RUN.*\/packages\/core$/{found=1} found && /Tests.*passed/{match($0,/[0-9]+/); print substr($0,RSTART,RLENGTH); exit}')
  A2A_COUNT=$(echo "$TEST_OUTPUT" 2>/dev/null | awk '/RUN.*\/packages\/a2a-server$/{found=1} found && /Tests.*passed/{match($0,/[0-9]+/); print substr($0,RSTART,RLENGTH); exit}')
  CLI_COUNT=${CLI_COUNT:-0}; CORE_COUNT=${CORE_COUNT:-0}; A2A_COUNT=${A2A_COUNT:-0}
  TOTAL=$((CLI_COUNT + CORE_COUNT + A2A_COUNT))
  echo -e "${GREEN}[PASS] Tests - ${TOTAL} tests (cli: ${CLI_COUNT}, core: ${CORE_COUNT}, a2a: ${A2A_COUNT})${NC}"
  TEST_FAILED=0
else
  OVERALL_EXIT=1
  FAILED=$(echo "$TEST_OUTPUT" | grep -oE '[0-9]+ failed' | head -1)
  PASSED=$(echo "$TEST_OUTPUT" | grep -oE '[0-9]+ passed' | tail -1)
  echo -e "${RED}[FAIL] Tests - ${FAILED:-some failed}, ${PASSED:-some passed}${NC}"
  TEST_FAILED=1
fi

# ------------------------------------------------------------
# 2. LINT
# ------------------------------------------------------------
if [ $LINT_EXIT -eq 0 ]; then
  CHECKED=$(echo "$LINT_OUTPUT" | grep -oE "Checked [0-9]+ files" | head -1)
  echo -e "${GREEN}[PASS] Lint - ${CHECKED:-files checked}${NC}"
  LINT_FAILED=0
else
  OVERALL_EXIT=1
  # ESLint format: "✖ 1 problem (1 error, 0 warnings)"
  ERRORS=$(echo "$LINT_OUTPUT" | grep -oE '\([0-9]+ error' | grep -oE '[0-9]+')
  WARNINGS=$(echo "$LINT_OUTPUT" | grep -oE '[0-9]+ warning' | tail -1 | grep -oE '[0-9]+')
  echo -e "${RED}[FAIL] Lint - ${ERRORS:-0} errors, ${WARNINGS:-0} warnings${NC}"
  LINT_FAILED=1
fi

# ------------------------------------------------------------
# 3. TYPECHECK
# ------------------------------------------------------------
if [ $TYPECHECK_EXIT -eq 0 ]; then
  echo -e "${GREEN}[PASS] Typecheck${NC}"
  TYPECHECK_FAILED=0
else
  OVERALL_EXIT=1
  ERROR_COUNT=$(echo "$TYPECHECK_OUTPUT" | grep -c "error TS")
  echo -e "${RED}[FAIL] Typecheck - ${ERROR_COUNT} errors${NC}"
  TYPECHECK_FAILED=1
fi

echo ""

# ------------------------------------------------------------
# ERROR DETAILS (grouped by file)
# ------------------------------------------------------------

# Test failures
if [ $TEST_FAILED -eq 1 ]; then
  echo -e "${RED}Test Failures:${NC}"
  echo "$TEST_OUTPUT" | grep -E "FAIL|✗|AssertionError|Error:" | head -20
  echo ""
fi

# Lint errors (grouped by file)
if [ $LINT_FAILED -eq 1 ]; then
  echo -e "${RED}Lint Errors:${NC}"
  echo "$LINT_OUTPUT" | grep -E "^packages/.*━" | awk -v dim="${DIM}" -v nc="${NC}" '
    {
      # Extract file:line:col from start of line
      split($1, parts, ":")
      file = parts[1]
      line_col = ":" parts[2] ":" parts[3]

      # Extract rule name (last part after /)
      match($0, /(lint|assist)\/[a-zA-Z]+\/[a-zA-Z]+/)
      rule = substr($0, RSTART, RLENGTH)
      gsub(/.*\//, "", rule)

      # Remove packages/ prefix
      gsub(/^packages\//, "", file)

      # Group by file
      if (file != current_file) {
        current_file = file
        print file
      }
      printf "  %s%s%s %s\n", dim, line_col, nc, rule
    }
  '
  echo ""
fi

# Type errors (grouped by file)
if [ $TYPECHECK_FAILED -eq 1 ]; then
  echo -e "${RED}Type Errors:${NC}"
  echo "$TYPECHECK_OUTPUT" | grep -E "\.tsx?\([0-9]+,[0-9]+\): error TS" | awk -v dim="${DIM}" -v nc="${NC}" '
    {
      # Extract file (everything before the parenthesis)
      match($0, /^[^(]+/)
      file = substr($0, RSTART, RLENGTH)
      gsub(/^packages\//, "", file)

      # Extract location (line,col)
      match($0, /\([0-9]+,[0-9]+\)/)
      location = substr($0, RSTART, RLENGTH)

      # Extract error message
      match($0, /error TS[0-9]+:.*/)
      error = substr($0, RSTART, RLENGTH)

      # Group by file
      if (file != current_file) {
        current_file = file
        print file
      }
      printf "  %s%s%s %s\n", dim, location, nc, error
    }
  '
  echo ""
fi

exit $OVERALL_EXIT
