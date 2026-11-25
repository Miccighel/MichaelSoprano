(() => {
  const groups = document.querySelectorAll("#about .profile-links-more > details");
  if (groups.length) {
    // Match the breakpoint where the portrait and bio switch to one column.
    const compact = window.matchMedia("(max-width: 991px)");
    const updateProfileGroups = () => {
      for (const group of groups) {
        const summary = group.querySelector("summary");
        if (compact.matches && group.contains(document.activeElement) && document.activeElement !== summary) {
          summary?.focus({ preventScroll: true });
        }
        group.open = !compact.matches;
      }
    };
    updateProfileGroups();
    compact.addEventListener("change", updateProfileGroups);
  }

  const links = [...document.querySelectorAll('#nav-menu a[href^="/#"]')];
  const sections = links.map(link => document.getElementById(link.hash.slice(1))).filter(Boolean);
  if (!sections.length) return;

  let active;
  let frame;
  const update = () => {
    frame = undefined;
    const root = document.documentElement;
    const anchorOffset = (parseFloat(getComputedStyle(root).scrollPaddingTop) || 0)
      + (parseFloat(getComputedStyle(sections[0]).scrollMarginTop) || 0);
    const line = Math.max(anchorOffset + 1, root.clientHeight * 0.22);
    // The final section cannot always reach the reading line above the footer.
    const atEnd = window.scrollY > 0 && root.scrollHeight - root.clientHeight - window.scrollY <= 2;
    const current = atEnd ? sections[sections.length - 1]
      : sections.findLast(section => section.getBoundingClientRect().top <= line) || sections[0];
    if (current === active) return;
    active = current;
    for (const link of links) {
      const selected = link.hash === `#${current.id}`;
      link.classList.toggle("active", selected);
      if (selected) link.setAttribute("aria-current", "location");
      else link.removeAttribute("aria-current");
    }
  };
  const schedule = () => {
    if (frame === undefined) frame = requestAnimationFrame(update);
  };
  window.addEventListener("scroll", schedule, { passive: true });
  window.addEventListener("resize", schedule);
  window.addEventListener("pageshow", schedule);
  window.addEventListener("load", schedule);
  schedule();
})();
