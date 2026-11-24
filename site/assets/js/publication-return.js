(() => {
  const link = document.querySelector("[data-publication-return]");
  if (!link || !document.referrer) return;

  const source = new URL(document.referrer);
  const archive = new URL(link.href);
  if (source.origin !== archive.origin || source.pathname !== archive.pathname) return;

  for (const key of ["q", "type", "year"]) {
    const value = source.searchParams.get(key);
    if (value?.trim()) archive.searchParams.set(key, value);
  }
  if (!archive.search) return;

  link.href = archive.href;
  link.querySelector("span").textContent = "Back to results";
})();
