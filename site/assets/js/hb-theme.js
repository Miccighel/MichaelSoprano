document.addEventListener("DOMContentLoaded", () => {
  const theme = window.siteTheme;
  if (!theme) return;

  const buttons = [...document.querySelectorAll(".theme-toggle")];
  const updateButtons = () => {
    const current = theme.current();
    buttons.forEach((button) => {
      button.dataset.theme = current;
      button.setAttribute("aria-pressed", String(current === "dark"));
    });
  };

  updateButtons();

  buttons.forEach((button) => {
    button.addEventListener("click", () => {
      const next = theme.current() === "dark" ? "light" : "dark";
      theme.set(next, true);
      updateButtons();
      document.dispatchEvent(
        new CustomEvent("hbThemeChange", {
          detail: {
            isDarkTheme: () => theme.current() === "dark",
          },
        }),
      );
    });
  });

  theme.systemTheme.addEventListener("change", () => {
    theme.useSystem();
    updateButtons();
  });
});
