# Michael Soprano — Hugo source

This directory contains the canonical website source. Setup, content creation,
CV synchronization, contact-form troubleshooting, and deployment instructions
are in the [repository README](../README.md).

All commands below run from this directory.

## Source structure

Content uses Hugo page bundles: each item has an `index.md` and optional images
or attachments. Public URLs are defined in `config/_default/hugo.yaml`.

| Content | Source | Public URL |
| --- | --- | --- |
| Publications | `content/publications/<directory>/` | `/publication/<directory>/` |
| Presentations, posters, and outreach | `content/events/<directory>/` | `/talk/<slug>/` |
| Teaching and posts | `content/blog/<directory>/` | `/post/<slug>/` |

Teaching pages support a parent/edition structure. An edition has
`course_parent: /post/<course>/`, `course_edition: '2026/2027'`,
`course_hidden: true`, and an explicit `url: /post/<course>/2026-2027/`.
The single page layout builds the navigation by academic year from these fields.
Hidden editions remain directly addressable and searchable but are omitted from
the Teaching homepage and archive; a retained legacy overview can use the same
`course_hidden` flag without becoming an edition. Keep tags and categories on
the parent course only so annual pages do not inflate topic counts.

Key fields are `identifiers.doi`, `publication.name`, resource `links` entries
with `type` and `url`, `event_start`, `event_end`, and the ordering `date`.
Use the content generator documented in the root README for complete examples.

Homepage sources:

- `data/authors/michael-soprano.yaml`: biography, education, interests, profiles.
- `data/home.yaml`: experience, visits, collection limits, and topic settings.
- `content/_index.md`: section order, headings, academic activity, and honors.
- `data/bibliometrics.json`: generated metrics, synchronized from the CV repo.
- `data/cv-sync.json`: generated integrity manifest for metrics and CV PDFs.
- `config/_default/menus.yaml`: navigation.

New content is included automatically in the relevant collections and archives.
The homepage topic threshold and explicit inclusions are configured in
`data/home.yaml` under `topics`.

## Build and checks

```bash
pnpm run check
```

This is the canonical local and CI command. It tests and verifies CV sync,
prepares local vendor assets, validates content, builds Hugo, generates the
Pagefind search index, and audits the output in `public/`. It also uses
Poppler's `pdfinfo` to inspect the links embedded in both CV PDFs and checks
that links back to this site's files match the generated paths exactly,
including filename case. Install Poppler locally before running the check;
the GitHub workflow installs it automatically.

The audit checks internal links, anchors, downloads, search coverage, content
completeness, collection limits, and accessibility basics such as the skip link.

Individual commands, useful while debugging:

| Command | Purpose |
| --- | --- |
| `pnpm run check:content` | Validate source content without rebuilding |
| `pnpm run build` | Build and index without the final generated-site audit |
| `ruby scripts/check-cv-pdf-links.rb` | Check site-hosted links in the CV PDFs after building |
| `ruby scripts/audit-build.rb` | Audit an existing production build |
| `pnpm run vendor` | Refresh generated fonts, icons, and Leaflet assets |
| `pnpm run check:links` | Optionally check external links after building |

External link checks are manual only, not part of CI. Unverifiable responses
such as HTTP 403/429 are reported separately; other failures return a nonzero
exit status. TLS verification remains enabled.

## Frontend architecture

`assets/css/custom.css` contains the historical layout rules.
`assets/css/design-system.css` loads afterward and defines the visual system:
colours, typography, spacing, focus states, and responsive adjustments.

Site scripts live in `assets/js/`. Fonts, icon fonts, and Leaflet are generated
from pinned dependencies into `static/vendor/`; do not edit or commit that
directory. Leaflet assets are loaded only on the homepage.

Hugo's development server does not regenerate the Pagefind index. Run a full
build and serve `public/` when verifying search behaviour.
