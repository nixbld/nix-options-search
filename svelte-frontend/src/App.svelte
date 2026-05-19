<script>
  const query = 'services';
  const versions = ['25.11', 'unstable'];
  const sources = [
    { name: 'NixOS', count: '10k+' },
    { name: 'Modular services', count: '0' },
    { name: 'Home Manager', count: '1.0k' }
  ];

  const results = [
    {
      title: 'services.activitywatch.enable',
      description: 'Whether to enable ActivityWatch service.',
      type: 'boolean',
      defaultValue: 'false',
      declaredIn: 'modules/services/activitywatch.nix'
    },
    {
      title: 'services.activitywatch.extraOptions',
      description: 'Extra command-line options for activitywatch.',
      type: 'list of string',
      defaultValue: '[ ]',
      declaredIn: 'modules/services/activitywatch.nix'
    },
    {
      title: 'services.activitywatch.package',
      description: 'The activitywatch package to use.',
      type: 'package',
      defaultValue: 'pkgs.activitywatch',
      declaredIn: 'modules/services/activitywatch.nix'
    },
    {
      title: 'services.activitywatch.settings',
      description: 'Raw settings passed to the service.',
      type: 'attribute set',
      defaultValue: '{ }',
      declaredIn: 'modules/services/activitywatch.nix'
    }
  ];

  let selectedVersion = versions[0];
  let selectedSource = sources[2].name;
  let expandedTitle = results[2].title;

  function selectVersion(version) {
    selectedVersion = version;
  }

  function selectSource(sourceName) {
    selectedSource = sourceName;
  }

  function toggleOption(title) {
    expandedTitle = expandedTitle === title ? null : title;
  }
</script>

<div class="page">
  <main class="container">
    <div class="search-row">
      <input value={query} />
      <button>Search</button>
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
            class="source-row {selectedSource === source.name ? 'active' : ''}"
            aria-pressed={selectedSource === source.name}
            on:click={() => selectSource(source.name)}
          >
            <span>{source.name}</span>
            <span class="badge">{source.count}</span>
          </button>
        {/each}
      </aside>

      <div class="results">
        <div class="result-header">
          <h2>Showing results 1-50 of <strong>1036 options.</strong></h2>
          <button class="sort">Sort: Best match ▾</button>
        </div>
        <p class="meta">Data from nixpkgs <code>d7a713c0</code>.</p>

        <ul>
          {#each results as result}
            <li>
              <a
                href="#"
                on:click|preventDefault={() => toggleOption(result.title)}
                aria-expanded={expandedTitle === result.title}
              >
                {result.title}
              </a>

              {#if expandedTitle === result.title}
                <div class="details">
                  <div class="detail-row"><span>Name</span><code>{result.title}</code></div>
                  <div class="detail-row"><span>Description</span><p>{result.description}</p></div>
                  <div class="detail-row"><span>Type</span><p>{result.type}</p></div>
                  <div class="detail-row"><span>Default</span><code>{result.defaultValue}</code></div>
                  <div class="detail-row"><span>Declared in</span><a href="#">{result.declaredIn}</a></div>
                </div>
              {/if}
            </li>
          {/each}
        </ul>
      </div>
    </section>
  </main>
</div>
