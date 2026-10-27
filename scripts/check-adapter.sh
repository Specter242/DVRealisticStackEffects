#!/usr/bin/env bash
# Check Realistic Stack Effects' reading of the game's own firebox and
# exhaust against the installed game's assemblies under Mono. Unity's native
# side is not needed.
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
dv="${DV_INSTALL_DIR:-$HOME/.local/share/Steam/steamapps/common/Derail Valley}"
project="$repo/tools/RealisticStackEffects.AdapterCheck"

command -v mono >/dev/null || { echo "mono is required" >&2; exit 1; }
# Fail on a failed build or any compiler warning; never run a stale checker.
if ! build="$(dotnet build "$project/RealisticStackEffects.AdapterCheck.csproj" -c Release -p:DvInstallDir="$dv" -nologo 2>&1)"; then
    grep -E "error" <<<"$build" | sort -u >&2
    echo "adapter check build failed" >&2
    exit 1
fi
if grep -q -E "warning CS" <<<"$build"; then
    grep -E "warning CS" <<<"$build" | sort -u >&2
    exit 1
fi
mono "$project/bin/Release/net48/RealisticStackEffects.AdapterCheck.exe"
