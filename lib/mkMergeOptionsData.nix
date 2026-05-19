{ pkgs }:
{
  releaseName,
  dataFiles,
}:
pkgs.runCommand "options-data-merged-${releaseName}"
  {
    nativeBuildInputs = [ pkgs.python3 ];
  }
  ''
    set -euo pipefail
    mkdir -p "$out"

    python3 - "$out/options-${releaseName}.json" ${builtins.concatStringsSep " " dataFiles} <<'PY'
from __future__ import annotations
import json
import sys
from pathlib import Path

out = Path(sys.argv[1])
inputs = [Path(p) for p in sys.argv[2:]]

all_options = []
last_updates = []
for p in inputs:
    data = json.loads(p.read_text())
    all_options.extend(data.get("options", []))
    lu = data.get("last_update")
    if lu:
        last_updates.append(lu)

all_options.sort(key=lambda o: o.get("title", ""))

out.write_text(json.dumps({
    "last_update": last_updates[-1] if last_updates else "",
    "options": all_options,
}, ensure_ascii=False))
PY
  ''
