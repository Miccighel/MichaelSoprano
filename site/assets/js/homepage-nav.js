(() => {
  document.addEventListener("click", (event) => {
    if (!event.target.closest('#nav-menu a[href^="/#"]')) return;
    const toggle = document.getElementById("nav-toggle");
    if (toggle) toggle.checked = false;
  });

  const links = [...document.querySelectorAll('#nav-menu a[href^="/#"]')];
  const sections = links.map((link) => document.querySelector(link.hash)).filter(Boolean);
  if (!sections.length || !("IntersectionObserver" in window)) return;

  const observer = new IntersectionObserver(
    (entries) => {
      const current = entries
        .filter((entry) => entry.isIntersecting)
        .sort((a, b) => b.intersectionRatio - a.intersectionRatio)[0];
      if (!current) return;
      links.forEach((link) => link.classList.toggle("active", link.hash === `#${current.target.id}`));
    },
    { rootMargin: "-20% 0px -65% 0px", threshold: [0, 0.25, 0.5] },
  );

  sections.forEach((section) => observer.observe(section));
})();
