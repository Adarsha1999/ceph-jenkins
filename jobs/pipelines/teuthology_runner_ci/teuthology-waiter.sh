#! /usr/bin/env bash
#
# teuthology-suite is invoked in teuthology-runner.sh with --wait, so the run is already
# complete when this step runs. Hook remains for future use (e.g. upload artifacts, notify).
set -euo pipefail
echo "teuthology-waiter: no-op (suite was scheduled with teuthology-suite --wait)."
