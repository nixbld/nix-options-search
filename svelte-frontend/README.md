# Svelte frontend mock

Client-side Svelte UI inspired by the provided screenshot.
It is wired to load option data from JSON files.

## Run

```bash
cd svelte-frontend
npm install
npm run dev
```

## Data input

Sync generated files automatically:

```bash
npm run sync:data
```

This copies from `../result` into:

- `svelte-frontend/public/data/options-25.11.json`
- `svelte-frontend/public/data/options-unstable.json`

You can also pass a custom source path:

```bash
node ./scripts/sync-options-data.mjs /path/to/site-output
```

Expected format:

```json
{
  "last_update": "...",
  "options": [
    {
      "title": "services.foo.enable",
      "loc": ["services", "foo", "enable"],
      "type": "boolean",
      "description": "...",
      "default": "false",
      "declarations": [{ "name": "...", "url": "..." }]
    }
  ]
}
```

## Build

```bash
npm run build
npm run preview
```
