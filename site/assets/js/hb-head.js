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

const relBase = root.dataset.hbbRelurl || "/";
const normalizedRelBase = relBase.endsWith("/") ? relBase : `${relBase}/`;
const buildAssetPath = (relativePath) => {
  const sanitizedPath = relativePath.startsWith("/") ? relativePath.slice(1) : relativePath;
  return `${normalizedRelBase}${sanitizedPath}`;
};

// Temporary compatibility surface for the search component. It will disappear
// when Pagefind is migrated to the local implementation.
window.hbb = {
  defaultTheme,
  relBase: normalizedRelBase,
  assetPaths: {
    pagefind: buildAssetPath("pagefind/pagefind.js"),
  },
  setDarkTheme: () => setTheme("dark"),
  setLightTheme: () => setTheme("light"),
};

document.addEventListener("DOMContentLoaded", () => {
  document.querySelectorAll("li input[type='checkbox'][disabled]").forEach((checkbox) => {
    checkbox.parentElement?.parentElement?.classList.add("task-list");
  });

  document.querySelectorAll(".task-list li").forEach((item) => {
    const textNode = [...item.childNodes].find(
      (node) => node.nodeType === Node.TEXT_NODE && node.textContent?.trim().length > 1,
    );
    if (!textNode) return;

    const label = document.createElement("label");
    textNode.after(label);
    const checkbox = item.querySelector("input[type='checkbox']");
    if (checkbox) label.appendChild(checkbox);
    label.appendChild(textNode);
  });
});
