# Bibliography review — 1 October 2026

Initial read-only review, followed by the user-approved corrections below. The initial findings remain documented for provenance.

## Corrections applied after user confirmation

- Keep the first online publication year, not automatically the print issue year. For TOIS, retain 2023 and May: the [authors' own repository](https://github.com/KevinRoitero/how-many-crowd-workers) includes the May 2023 **Just Accepted** citation, while Crossref describes the later August version and January 2024 issue. Added volume 42, issue 1, article 21 and 26 pages; the article identifier is corroborated by the final bibliographic record.
- Preserve and brace the complete family names `{Della Mea}`, `{La Barbera}` and `{Lizzio Bosco}` in author fields. Normalize MIE's author list to the same family-name-first style as the CV.
- MIE 2025: corrected ISBN to `978-1-64368-596-0`, confirmed by the [publisher's volume record](https://journals.sagepub.com/doi/book/10.3233/SHTI327). Corrected the editor names against that same record (Rosalynn Austin, Alexander Dejaco, Linda Dusseljee-Peute, Alaa Mohasseb, Pantelis Natsiavas, Haythem Nakkas).
- AIUCD 2019: inspected the user-supplied book of abstracts, its cover, copyright/ISBN page and contribution on printed pages **251–254** (PDF pages 253–256). Corrected the former single-page `251`, month March to January, volume title to the cover wording, and added editor Stefano Allegrezza. Title, author order and ISBN agree with the source. Local source: `/Users/michaelsoprano/Downloads/AIUCD2019-BoA_DEF.pdf`.
- TTO 2021: the [AIR institutional copy supplied by the user](https://air.uniud.it/retrieve/e27ce0ca-113d-055e-e053-6605fe0a7873/TTO2021_Predicting_and_Explaining_Truthfulness.pdf) is accessible. Its first page confirms the title and author order; the document contains 10 pages. Replaced the dead original URL in the website PDF button, website citation and CV bibliography. The unpaginated AIR copy does **not** independently confirm the existing proceedings range 18–27, which is left unchanged and remains a verification limit.
- Information Systems: retained July 2022. The [author-institution's published PDF](https://ir.cwi.nl/pub/32007/32007.pdf) states “Available online 29 July 2022”; December is the issue date, not a reason to change the first-online month.

All 38 citations now have external evidence for their basic identity; this does not mean all ancillary fields are verified. After corrections, the local comparison reports no differences for its compared fields between the website and CV entries. Abstracts, historical rankings and the TTO proceedings page range remain outside the completed verification.

## Scope and method

All 38 website `cite.bib` files parse successfully and match a record in the 38-entry CV bibliography. Compare titles, ordered author strings, years, venues, volumes, issues, pages, article numbers, DOI, ISBN, ISSN and publisher between these two local sets. There are three author-string differences, described below; other compared local fields agree after punctuation/case normalization.

Retrieved metadata for all 28 Crossref DOIs through the public `/works/{doi}` endpoint. Compared title plus subtitle, ordered authors, year, month, volume, issue, page/article number and available ISBN/ISSN. Venue and publisher metadata were retained for manual review, not automatically treated as equivalent to book titles or series. Publisher-deposited metadata is evidence, not infallible truth: names with particles and online/print dates need interpretation. See [Crossref's API description](https://www.crossref.org/documentation/retrieve-metadata/rest-api/).

Manually checked titles/authors and available bibliographic details for six CEUR papers against volumes [3937](https://ceur-ws.org/Vol-3937/), [2414](https://ceur-ws.org/Vol-2414/), [2441](https://ceur-ws.org/Vol-2441/), [3448](https://ceur-ws.org/Vol-3448/), [3802](https://ceur-ws.org/Vol-3802/) and [3486](https://ceur-ws.org/Vol-3486/). Checked the two arXiv records against [2506.09221](https://arxiv.org/abs/2506.09221) and [2605.04797](https://arxiv.org/abs/2605.04797). This covers basic external metadata for 36 of the 38 records, not every field in every entry.

## Findings to resolve

| Record | Finding | Recommended treatment |
| --- | --- | --- |
| Agent-Based Healthcare Chatbots, MIE 2025 | ISBN `978-1-64368-485-7` differs from Crossref's `9781643685960`. | Verify the ISBN in the publisher's book record/export before replacing it. [DOI](https://doi.org/10.3233/SHTI250434). |
| How Many Crowd Workers Do I Need?, TOIS | Volume and issue missing locally; Crossref gives **42(1)** and pages **1–26**. Local month is May 2023; Crossref reports online August 2023 and print January 2024. | Complete final citation from the publisher export; explicitly decide whether the year should represent online or issue publication. Do not silently change chronology. [DOI](https://doi.org/10.1145/3597201). |
| Transparent Assessment…, Information Systems | Local month July; Crossref's issue date is December 2022. | Check whether July represents online publication. Same year, volume and article number agree. [DOI](https://doi.org/10.1016/j.is.2022.102107). |
| Can The Crowd Judge Truthfulness?, PUC | Site uses `Mea, Vincenzo Della`; CV uses `Della Mea, Vincenzo`. | Normalize the intended family name consistently, rather than copying the Crossref split blindly. [DOI](https://doi.org/10.1007/s00779-021-01604-6). |
| How Many Crowd Workers Do I Need?, TOIS | Site uses `Barbera, David La`; CV uses `{La Barbera}, David`. | Preserve `La Barbera` as the family name consistently. |
| MIE 2025 | Site uses given-name-first authors; CV uses family-name-first. | Both are valid BibTeX forms; optional normalization for consistency, not a different author list. |

## Differences that are not errors

- IIR 2019: the CEUR volume index lists a different author order, but the [actual first page](https://ceur-ws.org/Vol-2441/paper4.pdf) confirms **Michael Soprano, Kevin Roitero, Stefano Mizzaro**, matching the local citation. Keep the local order.
- Crossref sometimes splits surnames (`Della Mea`, `La Barbera`, `Lizzio Bosco`) differently. No evidence of missing authors was found in the compared lists; these splits should not be propagated automatically.
- Elsevier article identifiers are stored in local `pages` fields (e.g. `102710`), whereas Crossref also reports `article-number`. This is a representation difference, not a missing article.
- ACM records commonly use `articleno` plus `numpages`; Crossref additionally reports ranges such as `1–53`. Not adding a redundant page range is not itself an error.
- Title comparisons include Crossref subtitles; the initially apparent omissions in ACM titles disappear when these are included.
- Online and print years differ for PUC, JDIQ and TOIS. The local year can represent online publication; a uniform editorial policy should be chosen before changing it.
- Nested braces around the IRCDL 2019 DOI are handled by the audit script; all 28 Crossref DOI records resolved after stripping grouping braces.

## Still unverified

- AIUCD 2019: official book of abstracts could not be retrieved through the browsing tool.
- E-BART, TTO 2021: official PDF was initially detected, but repeated access/first-page rendering returned 403; do not consider its author order and page range externally confirmed in this review.
- Abstracts, keywords, conference locations, editor lists, rankings in `note` (CORE, GGS, JCR/SJR and their historical years), and exact online/issue dates have not received a complete source-by-source audit.
- This review does not validate BibTeX name parsing in a rendered bibliography for every citation style.

## Repeatable diagnostic

From the website repository:

```sh
node site/scripts/audit-bibliography.mjs
node site/scripts/audit-bibliography.mjs --crossref
```

Both commands are read-only and print JSON. The first compares local records; the second additionally requests public Crossref metadata. Candidate differences are not confirmed errors and never cause automatic edits. Network checks are intentionally separate from the build.
