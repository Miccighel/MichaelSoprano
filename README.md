# Michael Soprano — personal website

Source for [michaelsoprano.com](https://michaelsoprano.com), built with HugoBlox.
The canonical website is entirely contained in [`site/`](site/); the previous
Wowchemy implementation remains available through the dedicated rollback
branches and is not duplicated in the current source tree.

## Quick start

Requirements:

- Node.js 24
- pnpm 10.14.0
- Hugo Extended 0.164.0
- Go, for Hugo modules

```bash
cd site
pnpm install --frozen-lockfile
pnpm run vendor
./scripts/check-content.rb
hugo server --disableFastRender
```

For content authoring, homepage settings, complete validation, and CV
synchronization, see [`site/README.md`](site/README.md).

## Production build

```bash
cd site
pnpm install --frozen-lockfile
pnpm run vendor
./scripts/check-content.rb
hugo --destination public --gc --minify --cleanDestinationDir
pnpm exec pagefind --site public
cd ..
ruby site/scripts/audit-build.rb
```

Generated files and local dependency caches are intentionally ignored by Git.

## Deployment and rollback

The validated build workflow publishes `master` to GitHub Pages. Pull requests
and development branches run the same validation without changing production.
The former site is preserved in `hugo-version`, and the previously published
output is preserved in `codex/legacy-gh-pages-2026-08-09`.
The complete recovery procedure is documented in
[`docs/ROLLBACK.md`](docs/ROLLBACK.md).

## CV PDFs

The LaTeX sources are maintained in the sibling `../LaTeX` repository. Build
and synchronize both language versions with:

```bash
cd ../LaTeX
./build_all.sh --sync-website ../Website
```

This updates only the canonical files in `site/static/media/CVs/`.
