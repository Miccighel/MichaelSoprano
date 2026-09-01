(() => {
  const search = document.getElementById("publication-search");
  const type = document.getElementById("publication-type-filter");
  const year = document.getElementById("publication-year-filter");
  const items = [...document.querySelectorAll("#publication-archive-list article")];
  const empty = document.getElementById("publication-archive-empty");
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
    empty.hidden = visible !== 0;
  };

  search.addEventListener("input", filter);
  type.addEventListener("change", filter);
  year.addEventListener("change", filter);

  const applyHashFilter = () => {
    if (!hashTypes[window.location.hash]) return;
    type.value = hashTypes[window.location.hash];
    filter();
  };
  applyHashFilter();
  window.addEventListener("hashchange", applyHashFilter);
})();
