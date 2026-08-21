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
  const toggleButtons = [...document.querySelectorAll("[data-search-toggle]")];
  const closeButtons = [...modal.querySelectorAll("[data-search-close]")];

  let pagefindPromise;
  let results = [];
  let selectedIndex = -1;
  let requestId = 0;
  let debounceTimer;
  let previouslyFocused;
  let previousBodyOverflow = "";

  const setLoading = (loading) => {
    loadingElement.classList.toggle("hidden", !loading);
    input.setAttribute("aria-busy", String(loading));
  };

  const setStatus = (message) => {
    statusElement.textContent = message;
  };

  const clearResults = () => {
    results = [];
    selectedIndex = -1;
    resultsElement.replaceChildren();
    input.removeAttribute("aria-activedescendant");
  };

  const selectResult = (index) => {
    if (!results.length) return;
    selectedIndex = (index + results.length) % results.length;

    results.forEach((result, resultIndex) => {
      const selected = resultIndex === selectedIndex;
      result.classList.toggle("is-selected", selected);
      result.setAttribute("aria-selected", String(selected));
    });

    const selectedResult = results[selectedIndex];
    input.setAttribute("aria-activedescendant", selectedResult.id);
    selectedResult.scrollIntoView({ block: "nearest" });
  };

  const createResult = (data, index) => {
    const link = resultTemplate.content.firstElementChild.cloneNode(true);
    link.id = `site-search-result-${index}`;
    link.href = data.url;

    const title = link.querySelector("h3");
    title.innerHTML = data.meta?.title || "Untitled";

    const excerpt = link.querySelector("p");
    excerpt.innerHTML = data.excerpt || "";

    link.addEventListener("mouseenter", () => selectResult(index));
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
      const search = await pagefind.search(query);
      const data = await Promise.all(search.results.slice(0, 10).map((result) => result.data()));
      if (currentRequest !== requestId) return;

      const elements = data.map(createResult);
      resultsElement.replaceChildren(...elements);
      results = elements;

      if (results.length) {
        selectResult(0);
        setStatus(`${results.length} results found.`);
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
    debounceTimer = window.setTimeout(runSearch, 250);
  };

  function openSearch(prefilledQuery = "") {
    if (!modal.hidden) return;
    previouslyFocused = document.activeElement;
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
    previouslyFocused?.focus();
  }

  toggleButtons.forEach((button) => {
    button.setAttribute("aria-controls", modal.id);
    button.setAttribute("aria-expanded", "false");
    button.addEventListener("click", () => openSearch(button.dataset.searchQuery || ""));
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
    } else if (event.key === "ArrowDown" && results.length) {
      event.preventDefault();
      selectResult(selectedIndex + 1);
    } else if (event.key === "ArrowUp" && results.length) {
      event.preventDefault();
      selectResult(selectedIndex - 1);
    } else if (event.key === "Enter" && selectedIndex >= 0) {
      event.preventDefault();
      results[selectedIndex].click();
    } else if (event.key === "Tab") {
      const focusable = [...modal.querySelectorAll("input, a[href], button:not([disabled])")].filter(
        (element) => !element.hidden && element.getClientRects().length,
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
