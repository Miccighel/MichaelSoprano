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

The preview contains the updated profile and bibliometrics, and renders all
legacy publications and talks. The remaining work is to convert the old front
matter to the current HugoBlox schema.
