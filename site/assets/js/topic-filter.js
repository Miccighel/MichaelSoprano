(() => {
  const directory = document.querySelector(".topic-directory");
  const filter = directory?.querySelector(".topic-filter");
  if (!filter) return;

  const search = filter.querySelector("#topic-query");
  const clear = filter.querySelector("[data-topic-clear]");
  const status = filter.querySelector("[data-topic-status]");
  const nav = directory.querySelector(".topic-letters");
  const letters = new Map([...nav.querySelectorAll("a")].map(link => [link.hash.slice(1), link]));
  const words = text => text.normalize("NFD").replace(/\p{M}/gu, "").toLowerCase().match(/[\p{L}\p{N}]+/gu) ?? [];
  const groups = [...directory.querySelectorAll(".topic-letter-group")].map(group => ({
    group,
    letter: letters.get(group.getAttribute("aria-labelledby")),
    entries: [...group.querySelectorAll("li")].map(item => ({
      item,
      variants: [item.querySelector(".topic-directory-link > span").textContent, ...(item.dataset.topicAliases ?? "").split("|")].map(words),
    })),
  }));
  const total = groups.reduce((count, {entries}) => count + entries.length, 0);

  const render = () => {
    const query = words(search.value);
    let count = 0;
    for (const {group, letter, entries} of groups) {
      let visible = 0;
      for (const {item, variants} of entries) {
        item.hidden = !variants.some(variant => query.every(token => variant.some(word => word.startsWith(token))));
        if (!item.hidden) visible++;
      }
      group.hidden = visible === 0;
      if (letter) letter.hidden = group.hidden;
      count += visible;
    }
    nav.hidden = count === 0;
    clear.hidden = !search.value;
    status.textContent = query.length === 0 ? "" : count === 0 ? "No topics match." : count + " of " + total + " topics";
  };

  const readQuery = () => {
    search.value = new URL(location.href).searchParams.get("q") ?? "";
    render();
  };
  const applyQuery = () => {
    const url = new URL(location.href);
    const value = search.value.trim();
    if (value) url.searchParams.set("q", value);
    else url.searchParams.delete("q");
    if (url.href !== location.href) history.replaceState(history.state, "", url);
    render();
  };
  search.addEventListener("input", applyQuery);
  clear.addEventListener("click", () => {
    search.value = "";
    applyQuery();
    search.focus();
  });
  window.addEventListener("popstate", readQuery);
  filter.hidden = false;
  readQuery();
})();
