#!/usr/bin/env bash
# Exercise the effects loader through Unity's native scene and asset cleanup
# in an isolated headless editor, never the running game, against the built
# bundle (or the one given).
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
unity="${UNITY_EDITOR:-$HOME/Unity/Hub/Editor/2019.4.40f1/Editor/Unity}"
bundle="${1:-$repo/fx/build/realisticstackeffects_fx}"
log="$repo/fx/build/stack-asset-check.log"

[[ -x "$unity" ]] || { echo "Unity 2019.4.40f1 not found at $unity" >&2; exit 1; }
[[ -f "$bundle" ]] || { echo "Effects bundle not found at $bundle" >&2; exit 1; }
[[ "$(basename "$bundle")" == realisticstackeffects_fx ]] || { echo "Expected a realisticstackeffects_fx bundle" >&2; exit 1; }
bundle="$(realpath "$bundle")"
project="$(mktemp -d /tmp/rse-asset-check-XXXXXX)"
trap 'rm -rf "$project"' EXIT
mkdir -p "$project/Assets" "$project/Packages" "$project/ProjectSettings" "$(dirname "$log")"
cp "$repo/fx/RealisticFiringFX/Packages/manifest.json" "$project/Packages/manifest.json"
cp "$repo/fx/RealisticFiringFX/ProjectSettings/ProjectVersion.txt" "$project/ProjectSettings/ProjectVersion.txt"
cp "$repo/src/RealisticStackEffects/StackAssets.cs" "$repo/tools/RealisticStackEffects.AssetCheck/StackAssetsCheck.cs" "$project/Assets/"

if ! DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1 timeout 180 "$unity" -batchmode -nographics -projectPath "$project" \
        -executeMethod StackAssetsCheck.Run -fxBundle "$bundle" -logFile "$log"; then
    tail -45 "$log" >&2
    exit 1
fi
grep -E 'ASSET CHECK PASS:|ALL ASSET LIFETIME CHECKS PASSED' "$log"
grep -q 'ALL ASSET LIFETIME CHECKS PASSED' "$log"
