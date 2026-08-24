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

## Dipendenze residue da HugoBlox

Il progetto possiede già homepage, menu, footer e layout specifici per
pubblicazioni, eventi e didattica. HugoBlox fornisce ancora:

1. CSS di base e variabili cromatiche del tema;
2. funzioni condivise per date degli eventi e icone;
3. render hook e shortcode generici;
4. alcuni campi di configurazione e front matter con namespace `hugoblox`.

## Sequenza di lavoro

1. Rendere locale il guscio globale della pagina. **Completato.**
2. Rendere autonome ricerca e gestione del tema. **Completato.**
3. Sostituire il `head` conservando integralmente SEO, favicon e JSON-LD.
   **Completato salvo il foglio Tailwind di base: identità, metadati, favicon,
   Open Graph/Twitter, JSON-LD, token grafici, librerie e bundle sono locali.**
4. Rendere locali layout generici, tassonomie, 404, RSS e sitemap.
   **404, RSS, sitemap, robots, pagina privacy, indici delle tassonomie e
   guscio delle pagine dei termini, pagine autore, renderer delle schede e
   paginatore, resolver dei profili autore e pipeline delle immagini
   completati; funzioni condivise per date degli eventi e icone in corso.**
5. Migrare i campi `hugoblox` verso uno schema neutro e aggiornare generatori
   e controlli dei contenuti.
6. Rimuovere il modulo, `go.mod`, `go.sum` e la configurazione non più usata.
7. Ripetere audit funzionale, confronto visivo e controllo completo degli URL.

## Stato del ramo

La pipeline corrente produce 476 pagine HTML, 981 file, 649 destinazioni
interne e 59 pagine indicizzate. La diminuzione rispetto alla baseline è
intenzionale: sono stati rimossi Alpine.js e 63 asset KaTeX mai utilizzati.
Contenuti, URL pubblici e conteggi editoriali restano invariati.

## Normalizzazione delle tassonomie

I sette tag presenti nei sorgenti con varianti di maiuscole sono associati a
metadati canonici. Hugo conserva gli stessi URL e le etichette delle pagine
esistenti, ma ora genera in modo deterministico `Amazon Mechanical Turk`,
`Crowd_Frame`, `Crowdsourcing`, `HITS`, `Network Analysis`, `Prolific` e
`Toloka` negli indici e nelle pagine dei termini.
