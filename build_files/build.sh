#!/usr/bin/bash
# Orchestrator: runs each numbered step in order inside the image build.
set -euo pipefail
export CTX=/ctx
for step in 10-packages 20-system-files 30-extensions 40-theme 50-branding 55-signing 60-services 90-finalize; do
    echo "::group::${step}"
    bash "$CTX/build_files/${step}.sh"
    echo "::endgroup::"
done
