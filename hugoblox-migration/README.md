# HugoBlox migration preview

This directory is an isolated, working preview of the migration from the
legacy Wowchemy site to HugoBlox. It leaves the production source tree and
deployment workflow untouched.

The preview includes independent copies of the legacy publications, talks,
posts, static assets, and profile image. The production source tree at the
repository root remains untouched while the new HugoBlox design and routes are
validated.

## Local build

Install the JavaScript dependencies once with `pnpm install`, then build with
Hugo Extended 0.164.0 or newer:

```sh
hugo --gc --minify
```

The preview contains the complete legacy profile, homepage sections,
publications, talks, teaching material, and static assets. Its front matter is
already normalised to the current HugoBlox schema; deployment promotion remains
intentionally separate from the production site.

## CI preview

The `HugoBlox preview` workflow builds this directory only on the migration
branch. It creates the Pagefind search index after Hugo builds, then uploads a
14-day `hugoblox-preview` artifact. It intentionally does not deploy to GitHub
Pages, so the production site and its custom domain remain unchanged.
