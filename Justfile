set shell := ["bash", "-euo", "pipefail", "-c"]

build-site:
	nix build .#svelte-frontend-with-data-pages

verify-declaration-links path='result':
    #!/usr/bin/env bash
    set -euo pipefail

    files=0
    declarations=0
    verified=0
    violations=0
    failed=0

    for file in "{{path}}"/data/*.json; do
        [ "$(basename "$file")" = "ui-config.json" ] && continue

        file_declarations=$(jq '[.options[]?.declarations[]?] | length' "$file")
        file_verified=$(jq '[.options[]?.declarations[]? | select((.url // "") | startswith("https://"))] | length' "$file")
        file_violations=$((file_declarations - file_verified))

        echo "Checking $(basename "$file"): $file_verified/$file_declarations https URLs ($file_violations violations)"

        files=$((files + 1))
        declarations=$((declarations + file_declarations))
        verified=$((verified + file_verified))
        violations=$((violations + file_violations))

        if [ "$file_violations" -ne 0 ]; then
            failed=1
            echo "::error file=$file::Found non-https declaration URLs ($file_violations bad, $file_verified good)"
            jq -r '.options[]?.declarations[]?.url // empty | select(startswith("https://") | not)' "$file" | sed 's/^/  - /'
        fi
    done

    echo "Verified $files files, $verified/$declarations https URLs, $violations violations"
    [ "$failed" -eq 0 ]

ci: build-site verify-declaration-links

serve:
	printf 'Serving at http://127.0.0.1:4445\n'
	nix run .#serve-svelte-frontend
