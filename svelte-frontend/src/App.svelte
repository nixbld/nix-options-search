<script>
  import { onMount } from 'svelte';

  let query = 'services';
  const versions = ['25.11', 'unstable'];
  const sources = ['NixOS', 'Modular services', 'Home Manager'];

  let selectedVersion = versions[0];
  let selectedSource = 'Home Manager';

  let options = [];
  let loading = false;
  let error = '';
  let lastUpdate = '';
  let expandedTitle = null;

  const sourceBadge = {
    NixOS: '10k+',
    'Modular services': '0',
    'Home Manager': '1.0k'
  };

  function detectSource(option) {
    const decl = (option.declarations?.[0]?.name || '').toLowerCase();
    const loc = (option.loc || []).join('.').toLowerCase();
    const hay = `${decl} ${loc}`;

    if (hay.includes('home-manager') || hay.includes('home.nix')) return 'Home Manager';
    if (hay.includes('nixos') || hay.includes('/modules/')) return 'NixOS';
    return 'Modular services';
  }

  async function loadOptions(version) {
    loading = true;
    error = '';
    expandedTitle = null;

    try {
      const res = await fetch(`/data/options-${version}.json`);
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      const data = await res.json();
      options = (data.options || []).map((o) => ({ ...o, source: detectSource(o) }));
      lastUpdate = data.last_update || '';
      expandedTitle = options[0]?.title ?? null;
    } catch (e) {
      options = [];
      error = `Failed to load /data/options-${version}.json (${e.message})`;
    } finally {
      loading = false;
    }
  }

  function selectVersion(version) {
    selectedVersion = version;
    loadOptions(version);
  }

  function toggleOption(title) {
    expandedTitle = expandedTitle === title ? null : title;
  }

  $: filtered = options
    .filter((o) => o.source === selectedSource)
    .filter((o) => o.title.toLowerCase().includes(query.trim().toLowerCase()))
    .slice(0, 50);

  $: totalInSource = options.filter((o) => o.source === selectedSource).length;

  onMount(() => {
    loadOptions(selectedVersion);
  });
</script>

<div class="page">
  <main class="container">
    <div class="search-row">
      <input bind:value={query} placeholder="Search options..." />
      <button type="button">Search</button>
    </div>

    <div class="channels">
      <span>Versions:</span>
      {#each versions as version}
        <button
          type="button"
          class="chip {selectedVersion === version ? 'filled' : ''}"
          aria-pressed={selectedVersion === version}
          on:click={() => selectVersion(version)}
        >
          {version}
        </button>
      {/each}
    </div>

    <section class="content">
      <aside class="card">
        <h3>Source</h3>
        {#each sources as source}
          <button
            type="button"
            class="source-row {selectedSource === source ? 'active' : ''}"
            aria-pressed={selectedSource === source}
            on:click={() => (selectedSource = source)}
          >
            <span>{source}</span>
            <span class="badge">{sourceBadge[source]}</span>
          </button>
        {/each}
      </aside>

      <div class="results">
        <div class="result-header">
          <h2>Showing results 1-{filtered.length} of <strong>{totalInSource} options.</strong></h2>
          <button class="sort" type="button">Sort: Best match ▾</button>
        </div>
        <p class="meta">
          {#if lastUpdate}Data updated {lastUpdate}. {/if}
          {#if loading}Loading...{/if}
          {#if error}{error}{/if}
        </p>

        <ul>
          {#each filtered as option}
            <li>
              <a
                href="#"
                on:click|preventDefault={() => toggleOption(option.title)}
                aria-expanded={expandedTitle === option.title}
              >
                {option.title}
              </a>

              {#if expandedTitle === option.title}
                <div class="details">
                  <div class="detail-row"><span>Name</span><code>{option.title}</code></div>
                  <div class="detail-row"><span>Description</span><p>{option.description || '-'}</p></div>
                  <div class="detail-row"><span>Type</span><p>{option.type || '-'}</p></div>
                  <div class="detail-row"><span>Default</span><code>{option.default || '-'}</code></div>
                  <div class="detail-row">
                    <span>Declared in</span>
                    <a href={option.declarations?.[0]?.url || '#'}>{option.declarations?.[0]?.name || '-'}</a>
                  </div>
                </div>
              {/if}
            </li>
          {/each}
        </ul>
      </div>
    </section>
  </main>
</div>
