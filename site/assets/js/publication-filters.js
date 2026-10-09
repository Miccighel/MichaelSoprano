(() => {
  const search = document.getElementById("publication-search");
  const type = document.getElementById("publication-type-filter");
  const year = document.getElementById("publication-year-filter");
  const items = [...document.querySelectorAll("#publication-archive-list article")];
  const groups = [...document.querySelectorAll("#publication-archive-list [data-publication-year-group]")];
  const empty = document.getElementById("publication-archive-empty");
  const count = document.getElementById("publication-result-count");
  const reset = document.getElementById("publication-filter-reset");
  if (!search || !type || !year || !empty) return;

  const hashTypes = { "#1": "paper-conference", "#2": "article-journal", "#7": "thesis" };
  const filter = () => {
    const query = search.value.trim().toLowerCase();
    let visible = 0;
    items.forEach((item) => {
      const matchesQuery = !query || `${item.dataset.title} ${item.dataset.authors}`.includes(query);
      const matchesType = !type.value || item.dataset.type === type.value;
      const matchesYear = !year.value || item.dataset.year === year.value;
      item.hidden = !(matchesQuery && matchesType && matchesYear);
      if (!item.hidden) visible += 1;
    });
    groups.forEach((group) => {
      group.hidden = !group.querySelector("article:not([hidden])");
    });
    empty.hidden = visible !== 0;
    if (count) count.textContent = `${visible} of ${items.length} ${items.length === 1 ? "publication" : "publications"}`;
    if (reset) reset.hidden = !(search.value || type.value || year.value);
  };

  search.addEventListener("input", filter);
  type.addEventListener("change", filter);
  year.addEventListener("change", filter);
  reset?.addEventListener("click", () => {
    search.value = "";
    type.value = "";
    year.value = "";
    if (hashTypes[window.location.hash]) {
      window.history.replaceState(null, "", window.location.pathname + window.location.search);
    }
    filter();
    search.focus();
  });

  const applyHashFilter = () => {
    if (!hashTypes[window.location.hash]) return;
    type.value = hashTypes[window.location.hash];
    filter();
  };
  applyHashFilter();
  filter();
  window.addEventListener("hashchange", applyHashFilter);
})();
