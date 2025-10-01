#!/bin/bash
set -e

TAG=${1:-latest}
echo "Building with tag: $TAG"

# Create artifacts directory
mkdir -p artifacts

# Generate SBOM
if command -v syft &> /dev/null; then
    syft . -o cyclonedx-json=artifacts/sbom.cyclonedx.json
    echo "SBOM generated successfully"
else
    echo "Syft not found - skipping SBOM generation"
fi

echo "Build completed successfully"