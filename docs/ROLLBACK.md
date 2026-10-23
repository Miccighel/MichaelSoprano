# Production deployment and rollback

## Normal deployment

1. Update the canonical source in `site/` on a development branch.
2. Open a pull request to `main` and wait for the `Website / Validate and
   build` check to pass.
3. Merge the pull request. The same validated build is uploaded to GitHub
   Pages automatically.
4. Verify the homepage, search, CV downloads, publications, presentations,
   teaching pages, and the custom domain.

Only a push to `main` can trigger the normal production deployment.

## Restore the former website

The legacy source is preserved in `hugo-version`. To restore it:

1. Open the Actions tab on GitHub.
2. Select **Legacy rollback**.
3. Choose **Run workflow** from `main`.
4. Wait for the protected `github-pages` deployment to complete.
5. Verify `https://michaelsoprano.com/` and the custom domain setting.

This operation rebuilds the preserved source and does not rewrite `main`.

The production branch was renamed from `master` to `main` on October 23,
2026. Both the normal deployment and legacy rollback share the `main`
concurrency group, and the `github-pages` environment permits deployment
from `main`. The legacy snapshot branches below retain their original names.

## Restore a previously generated snapshot

The former generated `gh-pages` output is preserved in
`codex/legacy-gh-pages-2026-08-09`. It is an emergency reference and should
not be used for normal content editing.

The source immediately before the Hugo-only production deployment is
preserved in `codex/pre-hugo-pure-deploy-2026-08-24`. Keep both snapshot
branches together with `hugo-version` while the current implementation remains
in active development.

## Custom domain

The canonical source contains `site/static/CNAME`, whose content must remain
`michaelsoprano.com`. The repository's Pages custom-domain setting must match
it. If GitHub shows **Site not found**, check both before changing DNS.
