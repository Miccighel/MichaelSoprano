const root = document.documentElement;
const defaultTheme = root.dataset.wcThemeDefault || "system";
const storageKey = "wc-color-theme";
const systemTheme = window.matchMedia("(prefers-color-scheme: dark)");

function storedTheme() {
  try {
    const value = localStorage.getItem(storageKey);
    return value === "dark" || value === "light" ? value : null;
  } catch (_error) {
    return null;
  }
}

function applyTheme(theme) {
  const isDark = theme === "dark";
  root.classList.toggle("dark", isDark);
  root.style.colorScheme = isDark ? "dark" : "light";
  return theme;
}

function resolvedTheme() {
  const stored = storedTheme();
  if (stored) return stored;
  if (defaultTheme === "dark" || defaultTheme === "light") return defaultTheme;
  return systemTheme.matches ? "dark" : "light";
}

function setTheme(theme, persist = false) {
  const applied = applyTheme(theme);
  if (persist) {
    try {
      localStorage.setItem(storageKey, applied);
    } catch (_error) {
      // The selected theme still applies when storage is unavailable.
    }
  }
  return applied;
}

function currentTheme() {
  return root.classList.contains("dark") ? "dark" : "light";
}

function useSystemTheme() {
  if (defaultTheme === "system" && !storedTheme()) {
    return applyTheme(systemTheme.matches ? "dark" : "light");
  }
  return currentTheme();
}

applyTheme(resolvedTheme());

window.siteTheme = {
  current: currentTheme,
  defaultTheme,
  set: setTheme,
  storageKey,
  systemTheme,
  useSystem: useSystemTheme,
};
