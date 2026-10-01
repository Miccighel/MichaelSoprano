(() => {
  const modal = document.getElementById("legacy-cite-modal");
  const code = document.getElementById("legacy-cite-code");
  const copy = document.getElementById("legacy-cite-copy");
  const download = document.getElementById("legacy-cite-download");
  if (!modal || !code || !copy || !download) return;

  // Build text nodes, never interpret citation contents as HTML.
  const highlightCitation = citation => {
    const tokens = /(@[a-zA-Z]+)(\s*\{)([^,\r\n]+)|(^[\t ]*)([a-zA-Z][\w-]*)(\s*=)|[{}=,]/gm;
    const fragment = document.createDocumentFragment();
    const append = (text, kind) => {
      if (!kind) { fragment.append(document.createTextNode(text)); return; }
      const span = document.createElement("span");
      span.className = `bibtex-${kind}`;
      span.textContent = text;
      fragment.append(span);
    };
    let offset = 0;
    for (const match of citation.matchAll(tokens)) {
      append(citation.slice(offset, match.index));
      if (match[1]) {
        append(match[1], "type"); append(match[2], "punctuation"); append(match[3], "key");
      } else if (match[5]) {
        append(match[4]); append(match[5], "field"); append(match[6], "punctuation");
      } else append(match[0], "punctuation");
      offset = match.index + match[0].length;
    }
    append(citation.slice(offset));
    code.replaceChildren(fragment);
  };

  let downloadUrl = "";
  let trigger = null;
  let previousOverflow = "";
  let copyTimer;
  const status = document.getElementById("legacy-cite-status");
  const resetCopy = () => {
    window.clearTimeout(copyTimer);
    copy.innerHTML = '<i class="fas fa-copy" aria-hidden="true"></i> Copy BibTeX';
    if (status) status.textContent = "";
  };
  const close = () => {
    if (modal.hidden) return;
    modal.hidden = true;
    document.body.style.overflow = previousOverflow;
    resetCopy();
    trigger?.focus();
  };

  document.addEventListener("click", async (event) => {
    const button = event.target.closest(".legacy-cite");
    if (!button) return;

    try {
      const response = await fetch(button.dataset.citeUrl);
      if (!response.ok) throw new Error("Citation unavailable");

      const citation = await response.text();
      highlightCitation(citation);
      if (downloadUrl) URL.revokeObjectURL(downloadUrl);
      downloadUrl = URL.createObjectURL(new Blob([citation], { type: "application/x-bibtex" }));
      download.href = downloadUrl;
      trigger = button;
      resetCopy();
      previousOverflow = document.body.style.overflow;
      document.body.style.overflow = "hidden";
      modal.hidden = false;
      copy.focus();
    } catch (_error) {
      button.textContent = "Unavailable";
    }
  });

  modal.addEventListener("click", (event) => {
    if (event.target === modal || event.target.closest(".legacy-cite-close")) close();
  });

  copy.addEventListener("click", async () => {
    try {
      await navigator.clipboard.writeText(code.textContent);
      copy.innerHTML = '<i class="fas fa-check" aria-hidden="true"></i> Copied';
      if (status) status.textContent = "BibTeX copied to clipboard.";
    } catch (_error) {
      copy.textContent = "Copy failed";
      if (status) status.textContent = "Copy failed. You can download the BibTeX file instead.";
    }
    window.clearTimeout(copyTimer);
    copyTimer = window.setTimeout(resetCopy, 1600);
  });

  document.addEventListener("keydown", (event) => {
    if (modal.hidden) return;
    if (event.key === "Escape") { event.preventDefault(); close(); }
    if (event.key === "Tab") {
      const controls = [...modal.querySelectorAll('button, a[href], [tabindex="0"]')];
      const first = controls[0], last = controls[controls.length - 1];
      if (event.shiftKey && document.activeElement === first) { event.preventDefault(); last.focus(); }
      else if (!event.shiftKey && document.activeElement === last) { event.preventDefault(); first.focus(); }
    }
  });

  document.addEventListener("focusin", event => {
    if (!modal.hidden && !modal.contains(event.target)) copy.focus();
  });

  window.addEventListener("pagehide", () => {
    if (downloadUrl) URL.revokeObjectURL(downloadUrl);
  });
})();
