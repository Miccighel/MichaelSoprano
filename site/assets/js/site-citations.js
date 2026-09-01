(() => {
  const modal = document.getElementById("legacy-cite-modal");
  const code = document.getElementById("legacy-cite-code");
  const copy = document.getElementById("legacy-cite-copy");
  const download = document.getElementById("legacy-cite-download");
  if (!modal || !code || !copy || !download) return;

  let downloadUrl = "";
  const close = () => {
    modal.hidden = true;
  };

  document.addEventListener("click", async (event) => {
    const button = event.target.closest(".legacy-cite");
    if (!button) return;

    try {
      const response = await fetch(button.dataset.citeUrl);
      if (!response.ok) throw new Error("Citation unavailable");

      const citation = await response.text();
      code.textContent = citation;
      if (downloadUrl) URL.revokeObjectURL(downloadUrl);
      downloadUrl = URL.createObjectURL(new Blob([citation], { type: "application/x-bibtex" }));
      download.href = downloadUrl;
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
    } catch (_error) {
      copy.textContent = "Copy failed";
    }
    window.setTimeout(() => {
      copy.innerHTML = '<i class="fas fa-copy" aria-hidden="true"></i> Copy';
    }, 1600);
  });

  document.addEventListener("keydown", (event) => {
    if (event.key === "Escape") close();
  });

  window.addEventListener("pagehide", () => {
    if (downloadUrl) URL.revokeObjectURL(downloadUrl);
  });
})();
