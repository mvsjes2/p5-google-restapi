#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

cd "$PROJECT_DIR"

echo "=== Step 1: Regenerate all exchanges from live API ==="
GOOGLE_RESTAPI_CONFIG=~/.google/rest_api.yaml \
GOOGLE_RESTAPI_LOGGER=t/etc/log4perl.conf \
prove -v t/run_unit_tests.t || true  # Drive tests will fail, that's expected

echo ""
echo "=== Step 2: Sanitize PII from all exchanges ==="
perl t/bin/sanitize_exchanges.pl

echo ""
echo "=== Step 3: Fix Drive.pm exchanges (drive123 doesn't exist) ==="
perl t/bin/fix_drive_exchanges.pl

echo ""
echo "=== Step 4: Verify all tests pass with regenerated exchanges ==="
prove -v t/run_unit_tests.t
