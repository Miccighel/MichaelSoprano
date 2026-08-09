# Michael Soprano — HugoBlox website

This directory is the canonical source of the HugoBlox migration. It contains
the complete profile, homepage, publications, presentations, teaching pages,
and static assets while the legacy production tree remains frozen at the
repository root.

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

## Local build

Install the JavaScript dependencies once with `pnpm install`, then use Hugo
Extended 0.164.0 or newer:

```bash
./scripts/check-content.rb
hugo --gc --minify --cleanDestinationDir
```

The generated site is written to `public/`. Search indexing can be generated
after the Hugo build with:

```bash
npx --yes pagefind@1.5.2 --site public
```

## CV PDFs

The sibling LaTeX repository builds and copies the English and Italian CVs
directly into the correct legacy and HugoBlox static directories:

```bash
cd ../../LaTeX
./build_all.sh --sync-website ../Website
```

## CI preview and deployment

The `HugoBlox preview` workflow validates and builds this directory on the
migration branch, generates the Pagefind index, and uploads a 14-day preview
artifact. It does not deploy to GitHub Pages, so the current production site
and custom domain remain unchanged until the migration is explicitly promoted.
