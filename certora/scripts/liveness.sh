#!/bin/bash

set -euxo pipefail

certoraRun \
    src/irm/Irm.sol \
    --verify Irm:certora/specs/liveness.spec \
    --msg "IRM liveness" \
    --solc_via_ir \
    "$@"
