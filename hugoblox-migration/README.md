# HugoBlox migration preview

This directory is an isolated, working preview of the migration from the
legacy Wowchemy site to HugoBlox. It leaves the production source tree and
deployment workflow untouched.

The preview temporarily mounts the legacy publications, talks, posts, static
assets, and profile image from the repository root. This lets us validate the
new HugoBlox design and routes before copying and normalising that content in
the final migration step.

## Local build

Install the JavaScript dependencies once with `pnpm install`, then build with
Hugo Extended 0.164.0 or newer:

```sh
hugo --gc --minify
```

The initial preview contains the updated profile and bibliometrics, and renders
all legacy publications and talks. The remaining work is to make the content
self-contained and convert the old front matter to the current HugoBlox schema.
