# Michael Soprano — personal website

Static academic website for [michaelsoprano.com](https://michaelsoprano.com), built with Hugo and the Wowchemy Academic theme.

## HugoBlox branch

On `codex/hugo-wowchemy-upgrade`, the canonical source of all new content is
the `site/` directory. The legacy source tree at the repository
root is retained as a frozen reference until the migration is promoted; do not
add new publications, events, or teaching pages there.

The complete authoring workflow, content locations, validation command, and
local build instructions are documented in
[`site/README.md`](site/README.md).

## Requirements

- Hugo Extended 0.87.0
- Go, to resolve the Hugo modules on the first build

## Local development

```bash
hugo server --disableFastRender --i18n-warnings
```

The generated site is written to `public/`, which is intentionally ignored by Git.

## Build

```bash
hugo --gc --minify --cleanDestinationDir
```

The source content lives in `content/`; static files such as CVs, slides, posters, and theses live in `static/media/`. Theme colors and fonts are configured in `data/`, while local presentation overrides are in `assets/scss/` and `layouts/`.

## Deployment

Pushing to `hugo-version` runs [the GitHub Pages workflow](.github/workflows/gh-pages.yml), which builds the site and publishes the generated output to `gh-pages`.

`netlify.toml` is retained for compatibility with Netlify-based previews and the bundled Wowchemy CMS.

## CV PDFs

The PDF sources are maintained in the sibling `../LaTeX` project. Its build
script can compile and synchronize both website source trees in one command:

```bash
cd ../LaTeX
./build_all.sh --sync-website ../Website
```

The resulting files are stored at:

- `static/media/CVs/Curriculum_Vitae_EN.pdf`
- `static/media/CVs/Curriculum_Vitae_IT.pdf`
- `site/static/media/CVs/Curriculum_Vitae_EN.pdf`
- `site/static/media/CVs/Curriculum_Vitae_IT.pdf`
