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
  const normalize = (value) => value.normalize("NFD").replace(/\p{M}/gu, "")
    .toLowerCase().replace(/[^\p{L}\p{N}]+/gu, " ").trim();
  const records = items.map(item => ({
    item,
    text: normalize([
      item.dataset.title, item.dataset.authors,
      item.querySelector(".publication-archive-meta")?.textContent, item.dataset.year,
    ].filter(Boolean).join(" ")),
  }));
  const filter = () => {
    const terms = normalize(search.value).split(" ").filter(Boolean);
    let visible = 0;
    records.forEach(({item, text}) => {
      const matchesQuery = terms.every(term => text.includes(term));
      const matchesType = !type.value || item.dataset.type === type.value;
      const matchesYear = !year.value || item.dataset.year === year.value;
      item.hidden = !(matchesQuery && matchesType && matchesYear);
      if (!item.hidden) visible += 1;
    });
    groups.forEach((group) => {
      group.hidden = !group.querySelector("article:not([hidden])");
    });
    empty.hidden = visible !== 0;
    const filtered = Boolean(search.value.trim() || type.value || year.value);
    if (count) count.textContent = `${filtered ? visible + " of " : ""}${items.length} ${items.length === 1 ? "publication" : "publications"}`;
    if (reset) reset.hidden = !filtered;
  };

  const fields = { q: search, type, year };
  const applyFromUrl = () => {
    const url = new URL(window.location.href);
    for (const [name, control] of Object.entries(fields)) {
      const fallback = name === "type" ? hashTypes[url.hash] || "" : "";
      control.value = url.searchParams.get(name) ?? fallback;
      if (control.tagName === "SELECT" && control.selectedIndex < 0) control.value = "";
    }
    filter();
  };
  const applyFromControls = () => {
    const url = new URL(window.location.href);
    for (const [name, control] of Object.entries(fields)) {
      const value = control.value.trim();
      if (value) url.searchParams.set(name, value);
      else url.searchParams.delete(name);
    }
    if (hashTypes[url.hash]) url.hash = "";
    if (url.href !== window.location.href) window.history.replaceState(window.history.state, "", url);
    filter();
  };
  search.addEventListener("input", applyFromControls);
  type.addEventListener("change", applyFromControls);
  year.addEventListener("change", applyFromControls);
  reset?.addEventListener("click", () => {
    for (const control of Object.values(fields)) control.value = "";
    applyFromControls();
    search.focus();
  });

  applyFromUrl();
  window.addEventListener("popstate", applyFromUrl);
  window.addEventListener("hashchange", applyFromUrl);
})();
