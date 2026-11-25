document.addEventListener("DOMContentLoaded", () => {
  const modal = document.querySelector("#site-search");
  if (!modal) return;

  const input = modal.querySelector("#site-search-input");
  const resultTemplate = modal.querySelector("#site-search-result-template");
  const resultsElement = modal.querySelector("#site-search-results");
  const introElement = modal.querySelector("[data-search-intro]");
  const loadingElement = modal.querySelector("[data-search-loading]");
  const emptyElement = modal.querySelector("[data-search-empty]");
  const errorElement = modal.querySelector("[data-search-error]");
  const statusElement = modal.querySelector("[data-search-status]");
  const more = modal.querySelector("[data-search-more]");
  const pageSize = 10;
  const toggleButtons = [...document.querySelectorAll("[data-search-toggle]")];
  const closeButtons = [...modal.querySelectorAll("[data-search-close]")];

  let pagefindPromise;
  let results = [];
  let matches = [];
  let selectedIndex = -1;
  let requestId = 0;
  let debounceTimer;
  let previouslyFocused;
  let drawerToggle;
  let previousBodyOverflow = "";

  const setLoading = (loading) => {
    loadingElement.classList.toggle("hidden", !loading);
    input.setAttribute("aria-busy", String(loading));
  };

  const setStatus = (message) => {
    statusElement.textContent = message;
  };

  const clearResults = () => {
    matches = [];
    more.hidden = true;
    more.disabled = false;
    results = [];
    selectedIndex = -1;
    resultsElement.replaceChildren();
    input.removeAttribute("aria-activedescendant");
    input.setAttribute("aria-expanded", "false");
  };

  const selectResult = (index, scroll = true) => {
    if (!results.length) return;
    selectedIndex = (index + results.length) % results.length;

    results.forEach((result, resultIndex) => {
      const selected = resultIndex === selectedIndex;
      result.classList.toggle("is-selected", selected);
      result.setAttribute("aria-selected", String(selected));
    });

    const selectedResult = results[selectedIndex];
    input.setAttribute("aria-activedescendant", selectedResult.id);
    if (scroll) selectedResult.scrollIntoView({ block: "nearest" });
  };

  const createResult = (data, index) => {
    const link = resultTemplate.content.firstElementChild.cloneNode(true);
    link.id = `site-search-result-${index}`;
    link.href = data.url;

    const title = link.querySelector("h3");
    title.textContent = data.meta?.title || "Untitled";
    const metadata = link.querySelector(".site-search-result-meta");
    if (metadata) {
      metadata.textContent = [data.meta?.kind, data.meta?.year, data.meta?.resource].filter(Boolean).join(" · ");
      metadata.hidden = !metadata.textContent;
    }

    const excerpt = link.querySelector("p");
    const venue = link.querySelector(".site-search-result-venue");
    venue.textContent = data.meta?.venue || "";
    venue.hidden = !venue.textContent;
    if (["Publication", "Presentation", "Topic"].includes(data.meta?.kind)) {
      excerpt.textContent = data.meta?.summary || "";
    } else {
      excerpt.innerHTML = data.excerpt || "";
    }

    link.addEventListener("mouseenter", () => selectResult(index, false));
    link.addEventListener("focus", () => selectResult(index));
    link.addEventListener("click", closeSearch);
    return link;
  };

  const loadPagefind = () => {
    if (!pagefindPromise) {
      pagefindPromise = import(modal.dataset.pagefindUrl)
        .then(async (pagefind) => {
          await pagefind.init();
          return pagefind;
        })
        .catch((error) => {
          pagefindPromise = undefined;
          throw error;
        });
    }
    return pagefindPromise;
  };

  const appendBatch = async (currentRequest) => {
    const start = results.length;
    more.disabled = true;
    const data = await Promise.all(matches.slice(start, start + pageSize).map(hit => hit.data()));
    if (currentRequest !== requestId) return;
    const elements = data.map((item, index) => createResult(item, start + index));
    resultsElement.append(...elements);
    results.push(...elements);
    const remaining = matches.length - results.length;
    more.textContent = `Show ${Math.min(pageSize, remaining)} more`;
    more.hidden = !remaining;
    more.disabled = false;
    const total = matches.length;
    setStatus(remaining ? `Showing ${results.length} of ${total} results.` : `${total} result${total === 1 ? "" : "s"} found.`);
    input.setAttribute("aria-expanded", "true");
    if (!start) selectResult(0);
    else {
      input.focus({ preventScroll: true });
      selectResult(start);
    }
  };

  more.addEventListener("click", async () => {
    const id = requestId;
    try { await appendBatch(id); }
    catch {
      if (id !== requestId) return;
      more.disabled = false;
      setStatus("Could not load more results. Please try again.");
    }
  });

  const runSearch = async () => {
    const query = input.value.trim();
    const currentRequest = ++requestId;
    clearResults();
    introElement.classList.toggle("hidden", Boolean(query));
    emptyElement.classList.add("hidden");
    errorElement.classList.add("hidden");

    if (!query) {
      setLoading(false);
      setStatus("");
      return;
    }

    setLoading(true);
    setStatus("Searching…");

    try {
      const pagefind = await loadPagefind();
      const topicTitle = query.replace(/\s+/g, " ").toLowerCase();
      const [search, exactTopics] = await Promise.all([
        pagefind.search(query),
        pagefind.search(null, { filters: { topicTitle } }),
      ]);
      if (currentRequest !== requestId) return;
      const exactTopicIds = new Set(exactTopics.results.map(hit => hit.id));
      matches = [...exactTopics.results, ...search.results.filter(hit => !exactTopicIds.has(hit.id))];
      if (matches.length) {
        await appendBatch(currentRequest);
      } else {
        emptyElement.classList.remove("hidden");
        setStatus("No results found.");
      }
    } catch (error) {
      if (currentRequest !== requestId) return;
      console.error("Unable to load the local search index.", error);
      errorElement.classList.remove("hidden");
      setStatus("Search is temporarily unavailable.");
    } finally {
      if (currentRequest === requestId) setLoading(false);
    }
  };

  const scheduleSearch = () => {
    window.clearTimeout(debounceTimer);
    requestId += 1;
    clearResults();
    setStatus("");
    debounceTimer = window.setTimeout(runSearch, 250);
  };

  function openSearch(prefilledQuery = "", trigger = document.activeElement) {
    if (!modal.hidden) return;
    previouslyFocused = trigger;
    const navToggle = document.getElementById("nav-toggle");
    drawerToggle = navToggle?.getAttribute("aria-expanded") === "true" && trigger?.closest("#nav-menu")
      ? navToggle
      : null;
    previousBodyOverflow = document.body.style.overflow;
    modal.hidden = false;
    document.body.style.overflow = "hidden";
    toggleButtons.forEach((button) => button.setAttribute("aria-expanded", "true"));
    input.value = prefilledQuery;
    input.focus();
    loadPagefind().catch(() => {});
    if (prefilledQuery) runSearch();
  }

  function closeSearch() {
    if (modal.hidden) return;
    requestId += 1;
    window.clearTimeout(debounceTimer);
    modal.hidden = true;
    document.body.style.overflow = previousBodyOverflow;
    toggleButtons.forEach((button) => button.setAttribute("aria-expanded", "false"));
    input.value = "";
    clearResults();
    introElement.classList.remove("hidden");
    emptyElement.classList.add("hidden");
    errorElement.classList.add("hidden");
    setLoading(false);
    setStatus("");
    // Moving focus into search closes the mobile drawer, hiding its links.
    for (const target of [drawerToggle, previouslyFocused, ...toggleButtons]) {
      if (!target?.isConnected || target === document.body) continue;
      target.focus({ preventScroll: true });
      if (document.activeElement === target) break;
    }
    previouslyFocused = drawerToggle = null;
  }

  toggleButtons.forEach((button) => {
    button.setAttribute("aria-controls", modal.id);
    button.setAttribute("aria-expanded", "false");
    button.addEventListener("click", () => openSearch(button.dataset.searchQuery || "", button));
  });
  closeButtons.forEach((button) => button.addEventListener("click", closeSearch));
  input.addEventListener("input", scheduleSearch);

  document.addEventListener("keydown", (event) => {
    if ((event.metaKey || event.ctrlKey) && event.key.toLowerCase() === "k") {
      event.preventDefault();
      modal.hidden ? openSearch() : closeSearch();
      return;
    }

    if (modal.hidden) return;
    if (event.key === "Escape") {
      event.preventDefault();
      closeSearch();
    } else if (["ArrowDown", "ArrowUp"].includes(event.key) && results.length &&
               (event.target === input || results.includes(event.target))) {
      event.preventDefault();
      selectResult(selectedIndex + (event.key === "ArrowDown" ? 1 : -1));
      if (event.target !== input) results[selectedIndex].focus();
    } else if (event.key === "Enter" && event.target === input && selectedIndex >= 0) {
      event.preventDefault();
      results[selectedIndex].click();
    } else if (event.key === "Tab") {
      const focusable = [...modal.querySelectorAll("input, a[href], button:not([disabled])")].filter(
        (element) => element.tabIndex >= 0 && !element.hidden && element.getClientRects().length,
      );
      if (!focusable.length) return;
      const first = focusable[0];
      const last = focusable[focusable.length - 1];
      if (event.shiftKey && document.activeElement === first) {
        event.preventDefault();
        last.focus();
      } else if (!event.shiftKey && document.activeElement === last) {
        event.preventDefault();
        first.focus();
      }
    }
  });
});
