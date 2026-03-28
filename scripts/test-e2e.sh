#!/bin/bash
# scripts/test-e2e.sh - E2E test runner for task_mbt

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TESTDATA_DIR="$PROJECT_ROOT/testdata"
CLI_CMD="moon run $PROJECT_ROOT/cmd/cli"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters
TOTAL=0
PASSED=0
FAILED=0
SKIPPED=0

echo "🧪 task_mbt E2E Tests"
echo "===================="
echo ""

# Test a single directory
run_test() {
    local test_dir="$1"
    local taskfile="$test_dir/Taskfile.yml"
    
    if [ ! -f "$taskfile" ]; then
        # Try Taskfile.yaml
        taskfile="$test_dir/Taskfile.yaml"
    fi
    
    if [ ! -f "$taskfile" ]; then
        echo -e "${YELLOW}⊘ SKIP${NC} $(basename "$test_dir") - No Taskfile found"
        SKIPPED=$((SKIPPED + 1))
        return
    fi
    
    TOTAL=$((TOTAL + 1))
    
    # Run task_mbt in the test directory
    cd "$test_dir"
    if output=$($CLI_CMD 2>&1); then
        echo -e "${GREEN}✓ PASS${NC} $(basename "$test_dir")"
        PASSED=$((PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC} $(basename "$test_dir")"
        echo "  Error: $output"
        FAILED=$((FAILED + 1))
    fi
    cd "$PROJECT_ROOT"
}

# Run tests for each directory
for test_dir in "$TESTDATA_DIR"/*/; do
    if [ -d "$test_dir" ]; then
        run_test "$test_dir"
    fi
done

# Summary
echo ""
echo "===================="
echo "Test Summary:"
echo -e "  Total:   $TOTAL"
echo -e "  ${GREEN}Passed:  $PASSED${NC}"
echo -e "  ${RED}Failed:  $FAILED${NC}"
echo -e "  ${YELLOW}Skipped: $SKIPPED${NC}"
echo ""

if [ $FAILED -gt 0 ]; then
    exit 1
else
    echo "🎉 All tests passed!"
    exit 0
fi
