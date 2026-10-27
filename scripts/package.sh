#!/usr/bin/env bash
# Build a Unity Mod Manager package of Realistic Stack Effects from the public
# source tree: dist/RealisticStackEffects-<version>.zip.
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
dv="${DV_INSTALL_DIR:-$HOME/.local/share/Steam/steamapps/common/Derail Valley}"
unity="${UNITY_EDITOR:-$HOME/Unity/Hub/Editor/2019.4.40f1/Editor/Unity}"
out="$repo/src/RealisticStackEffects/bin/Release/net48"
bundle="$repo/fx/build/realisticstackeffects_fx"
version="$(python3 -c 'import json, sys; print(json.load(open(sys.argv[1]))["Version"])' "$repo/src/RealisticStackEffects/Info.json")"
zipfile="$repo/dist/RealisticStackEffects-$version.zip"

dotnet test "$repo/tests/RealisticStackEffects.Core.Tests" -c Release -nologo -v quiet
"$repo/scripts/check-adapter.sh"
dotnet build "$repo/src/RealisticStackEffects/RealisticStackEffects.csproj" \
    -c Release -p:DvInstallDir="$dv" -warnaserror -nologo

if [[ -x "$unity" ]]; then
    "$repo/scripts/build-fx.sh"
elif [[ ! -f "$bundle" ]]; then
    echo "No effects bundle at $bundle and no Unity to build one" >&2
    exit 1
fi

mkdir -p "$repo/dist"
stage="$(mktemp -d "$repo/dist/package.XXXXXX")"
trap 'rm -rf "$stage"' EXIT
mkdir "$stage/RealisticStackEffects"
cp "$out/Info.json" "$out/RealisticStackEffects.dll" "$out/RealisticStackEffects.Core.dll" \
    "$bundle" "$repo/README.md" "$repo/CHANGELOG.md" "$repo/LICENSE" "$stage/RealisticStackEffects/"
files=(RealisticStackEffects/Info.json RealisticStackEffects/RealisticStackEffects.dll
       RealisticStackEffects/RealisticStackEffects.Core.dll RealisticStackEffects/realisticstackeffects_fx
       RealisticStackEffects/README.md RealisticStackEffects/CHANGELOG.md RealisticStackEffects/LICENSE)

# Select the archive's contents explicitly; never include assemblies copied
# for adapter checks, local settings, logs, or development documents.
rm -f "$zipfile"
(cd "$stage" && zip -q -X "$zipfile" "${files[@]}")
echo "Built $zipfile"
(cd "$(dirname "$zipfile")" && sha256sum "$(basename "$zipfile")")
