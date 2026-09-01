# Migrazione conservativa a Hugo

La migrazione rimuove progressivamente HugoBlox senza modificare contenuti,
URL pubblici o presentazione del sito. Il ramo di produzione `master` resta
invariato fino alla verifica completa del risultato.

## Invarianti

- Tutti i contenuti e gli allegati devono rimanere disponibili.
- Gli URL pubblici e i redirect storici devono restare compatibili.
- Ogni passaggio deve superare validazione dei sorgenti, build, Pagefind e
  audit del sito generato.
- Le differenze visive appartengono a una fase successiva e separata.
- Il modulo HugoBlox viene rimosso solo dopo aver sostituito ogni funzione
  effettivamente utilizzata.

## Baseline

La baseline del ramo `master` al commit `fb437fc8` produce:

- 476 pagine HTML;
- 1.045 file generati;
- 650 destinazioni interne univoche;
- 38 pubblicazioni;
- 16 eventi;
- 3 contenuti didattici;
- 59 pagine indicizzate da Pagefind.

## Autonomia da HugoBlox

Il progetto possiede ormai localmente homepage, menu, footer, layout, funzioni,
traduzioni, risorse JavaScript e intero albero CSS effettivamente compilato.
Il mount del modulo, i parametri di configurazione storici, `go.mod` e `go.sum`
sono stati rimossi dopo una build completa senza modulo.

## Sequenza di lavoro

1. Rendere locale il guscio globale della pagina. **Completato.**
2. Rendere autonome ricerca e gestione del tema. **Completato.**
3. Sostituire il `head` conservando integralmente SEO, favicon e JSON-LD.
   **Completato: identità, metadati, favicon, Open Graph/Twitter, JSON-LD,
   token grafici, librerie, bundle e foglio Tailwind di base sono locali.**
4. Rendere locali layout generici, tassonomie, 404, RSS e sitemap.
   **404, RSS, sitemap, robots, pagina privacy, indici delle tassonomie e
   guscio delle pagine dei termini, pagine autore, renderer delle schede e
   paginatore, resolver dei profili autore e pipeline delle immagini
   formattazione delle date evento, resolver SVG, catalogo minimo delle
   icone e pagina Privacy completati. La pagina Privacy usa ora un layout
   intenzionalmente semplice, senza sidebar, indice o condivisione superflui.
   Anche il render hook dei collegamenti Markdown è locale; gli
   altri render hook e gli shortcode del modulo non sono usati dai contenuti.
   componenti non utilizzati sono stati rimossi.**
5. Migrare i campi `hugoblox` verso uno schema neutro e aggiornare generatori
   e controlli dei contenuti. **Completato: i 30 DOI usano ora
   `identifiers.doi`; generatori, template e audit sono aggiornati.**
6. Rimuovere il modulo, `go.mod`, `go.sum` e la configurazione non più usata.
   **Completato: anche il workflow non installa più Go.**
7. Ripetere audit funzionale, confronto visivo e controllo completo degli URL.
   **Completato: pipeline verde, tre screenshot campione invarianti, menu e
   ricerca interattivi, nessun errore in console.**

## Stato del ramo

La pipeline corrente con Hugo 0.165 produce 476 pagine HTML, 969 file, 650
destinazioni interne e 59 pagine indicizzate. La diminuzione rispetto alla
baseline è intenzionale: sono stati rimossi Alpine.js, 63 asset KaTeX e i
componenti CSS/JavaScript generici mai utilizzati.
Contenuti, URL pubblici e conteggi editoriali restano invariati.

## Normalizzazione delle tassonomie

I sette tag presenti nei sorgenti con varianti di maiuscole sono associati a
metadati canonici. Hugo conserva gli stessi URL e le etichette delle pagine
esistenti, ma ora genera in modo deterministico `Amazon Mechanical Turk`,
`Crowd_Frame`, `Crowdsourcing`, `HITS`, `Network Analysis`, `Prolific` e
`Toloka` negli indici e nelle pagine dei termini.
