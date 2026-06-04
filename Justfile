set shell := ["bash", "-euo", "pipefail", "-c"]

build-site:
	nix build .#svelte-frontend-with-data-pages

inspect-declaration-links path='result':
	jq -r '.options[].declarations[].url' {{path}}/data/agentspace-unstable.json | sort | uniq -c

verify-declaration-links path='result':
	for file in {{path}}/data/*.json; do [ "$(basename "$file")" = "ui-config.json" ] && continue; if ! jq -e 'all(.options[]?.declarations[]?; ((.url // "") | startswith("https://")))' "$file" >/dev/null; then echo "::error file=$file::Found non-https declaration URLs"; jq -r '.options[]?.declarations[]?.url // empty | select(startswith("https://") | not)' "$file"; exit 1; fi; done

ci: build-site inspect-declaration-links verify-declaration-links

serve:
	printf 'Serving at http://127.0.0.1:4445\n'
	nix run .#serve-svelte-frontend
