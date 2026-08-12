# Michael Soprano — HugoBlox website

This directory is the canonical and self-contained source of the HugoBlox
website. It contains the complete profile, homepage, publications,
presentations, teaching pages, and static assets.

## Content structure

Content is stored as Hugo page bundles. Every item has its own directory with
an `index.md` file and, when needed, images or downloadable files beside it.

| Content | Source directory | Public URL |
| --- | --- | --- |
| Publications | `content/publications/<slug>/` | `/publication/<slug>/` |
| Presentations and posters | `content/events/<slug>/` | `/talk/<generated-slug>/` |
| Teaching | `content/blog/<slug>/` | `/post/<slug>/` |

The source directory names follow the current HugoBlox schema. Public URLs
retain the historical website structure through the permalink configuration.

## Create new content

Run the content generator from this directory:

```bash
./scripts/new-content.rb publication my-new-paper
./scripts/new-content.rb event conference-name-2027
./scripts/new-content.rb teaching new-course
```

The generator creates the correct directory and a draft `index.md` containing
the fields required by the selected content type. Complete the placeholders,
place any bundle assets in the same directory, and change `draft` to `false`
when the page is ready.

The most important HugoBlox fields are:

- publication DOI: `hugoblox.ids.doi`;
- publication venue: `publication.name`;
- downloadable resources: entries in `links` with `type` and `url`;
- event dates: `event_start` and `event_end`;
- page date used for ordering: `date`.

New publications, events, teaching pages, and tags are automatically included
in the homepage collections and archives. Topics with at least three associated
pages automatically appear in the homepage topic cloud; historically important
lower-frequency topics can be included in `data/home.yaml`.

## Edit the homepage

- `data/home.yaml` contains the profile, social links, interests, education,
  visits, and professional experience.
- `content/_index.md` contains the section order and the editable text for
  bibliometrics, academic activity, and honors.
- `config/_default/menus.yaml` contains the navigation menu.

These are the only canonical homepage sources; no generated legacy data file
or synchronization step is required.

## Validate content

Before building, run:

```bash
./scripts/check-content.rb
```

The validator checks required front matter, supported publication types,
event date order, link structure, duplicate slugs, homepage data, and drafts.
The preview workflow runs the same validation automatically before every CI
build.

After building the site and its search index, run the generated-site audit
from the repository root:

```bash
ruby site/scripts/audit-build.rb
```

This second check scans every generated HTML page, verifies internal links,
anchors, downloadable files, and search coverage, confirms that each
publication, presentation, and teaching page was rendered exactly once, and
checks that the rendered content is complete and searchable.

A scheduled CI run also checks external links once a week. It can be run
locally after a production build with:

```bash
ruby site/scripts/check-external-links.rb
```

## Local build

Use Node.js 24, pnpm 10.14.0, and Hugo Extended 0.164.0:

```bash
./scripts/check-content.rb
pnpm run vendor
hugo --gc --minify --cleanDestinationDir
pnpm exec pagefind --site public
cd .. && ruby site/scripts/audit-build.rb
```

The generated site is written to `public/`. Search indexing can be generated
after the Hugo build with:

```bash
pnpm exec pagefind --site public
```

`pnpm run vendor` prepares the pinned, self-hosted fonts, icon fonts, and
Leaflet files in `static/vendor/`. That generated directory is intentionally
ignored by Git and must be refreshed after dependency updates.

## CV PDFs

The sibling LaTeX repository builds and copies the English and Italian CVs
directly into the canonical static directory:

```bash
cd ../../LaTeX
./build_all.sh --sync-website ../Website
```

## CI preview and deployment

The website workflow validates and builds every pull request and `master`
update, generates the Pagefind index, and retains a short-lived preview
artifact. Only a successful push to `master` can deploy to GitHub Pages.
