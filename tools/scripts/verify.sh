#!/usr/bin/env bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}================================================================================${NC}"
echo -e "${BLUE}PONTIFEX PLANETARY TRANSIT FABRIC VERIFICATION HARNESS${NC}"
echo -e "${BLUE}================================================================================${NC}"

# Step 1: Em Dash Absence Assertion (Zero tolerance)
echo -n "[1/7] Scanning codebase for forbidden em dashes... "
EM_DASH_COUNT=$(python3 -c "
import os
count = 0
for root, dirs, files in os.walk('.'):
    if any(p in root for p in ['.git', '.terraform', '.generated', 'bin']):
        continue
    for f in files:
        p = os.path.join(root, f)
        try:
            with open(p, 'rb') as fp:
                if b'\xe2\x80\x94' in fp.read():
                    count += 1
                    print(f'Em dash detected in: {p}')
        except Exception:
            pass
print(count)
")

if [ "$EM_DASH_COUNT" -gt 0 ]; then
    echo -e "${RED}FAILED (Detected forbidden em dash in codebase)${NC}"
    exit 1
fi
echo -e "${GREEN}PASSED (0 em dashes)${NC}"

# Step 2: OpenTofu Format Check
echo -n "[2/7] Running OpenTofu format check... "
tofu fmt -check -recursive > /dev/null
echo -e "${GREEN}PASSED${NC}"

# Step 3: OpenTofu Syntax and Static Validation
echo -n "[3/7] Running OpenTofu structural validation... "
tofu validate > /dev/null
echo -e "${GREEN}PASSED${NC}"

# Step 4: OpenTofu Native Test Suites
echo "[4/7] Executing OpenTofu native test suites (.tftest.hcl)..."
tofu test
echo -e "${GREEN}OpenTofu test suites passed${NC}"

# Step 5: OpenTofu Local Synthesis and Apply
echo -n "[5/7] Compiling planetary manifests via OpenTofu apply... "
tofu apply -auto-approve > /dev/null
echo -e "${GREEN}PASSED${NC}"

# Step 6: Go CLI Test Suite
echo "[6/7] Running Go CLI test harness..."
(cd tools/cli && go test -v ./...)
echo -e "${GREEN}Go test harness passed${NC}"

# Step 7: CLI Audit and Inspection Pass
echo "[7/7] Running Pontifex CLI verification pass..."
(cd tools/cli && go build -o pontifex .)
./tools/cli/pontifex audit-chain
./tools/cli/pontifex verify-pki | tail -n 5
rm -f ./tools/cli/pontifex
echo -e "${GREEN}CLI verification passed${NC}"

echo -e "${GREEN}================================================================================${NC}"
echo -e "${GREEN}ALL VERIFICATION GATES PASSED (100% CLEAN)${NC}"
echo -e "${GREEN}================================================================================${NC}"
