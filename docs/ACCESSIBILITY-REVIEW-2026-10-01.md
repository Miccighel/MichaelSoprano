# Typography and accessibility review

Changes: shared readable metadata and label scales, relative root font size,
44 px minimum height for principal controls, stronger input outlines,
readable disabled publication entries, full tooltip titles, larger chart axes,
theme-aware line colors, one homepage h1 with section h2 headings, and a polite
live region announcing publication, year and cumulative citations on keyboard
navigation. Small decorative icons are not informative text.

Verification:

- Text palette contrast is tested at 4.5:1 against background, alternate
  background, surface and primary soft background in both themes. Control
  outlines are tested at 3:1 against the main background.
- Keyboard tests verify point navigation, selection, announcements and leaving
  the chart; the live status was also inspected in the browser accessibility tree.
- Browser checks at 320 CSS px found no document horizontal overflow on the
  homepage, citation history, publications archive, Web Applications 2025/2026
  and privacy page. Search and sort fields on mobile render at 16 px.
- The citation page was checked at 582 CSS px, the layout width corresponding
  to a 1164 px viewport at 200% zoom, and at normal desktop width in both themes.
  This checks reflow, not native browser zoom or text-only magnification.
- Full build, content audit, internal targets and CV synchronization checks pass.

Limits: this is not a WCAG conformance audit. No audible VoiceOver/NVDA session
was performed; the live-region implementation and exposed status were verified,
not the exact speech behavior of every assistive technology. Browser sample
checks are not visual verification of all 364 generated pages. Native zoom,
text-only enlargement and human screen-reader testing remain useful final checks.
