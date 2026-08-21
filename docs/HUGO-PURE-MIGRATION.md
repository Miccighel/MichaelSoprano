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

1. metadati, favicon, JSON-LD e asset inclusi nel `head`;
2. CSS di base e variabili cromatiche del tema;
3. assemblaggio delle librerie JavaScript, che carica ancora Alpine anche se
   ricerca e tema non ne dipendono più;
4. layout generici, tassonomie, pagina autore, 404, RSS e sitemap;
5. render hook e shortcode generici;
6. alcuni campi di configurazione e front matter con namespace `hugoblox`.

## Sequenza di lavoro

1. Rendere locale il guscio globale della pagina. **Completato.**
2. Rendere autonome ricerca e gestione del tema. **Completato.**
3. Sostituire il `head` conservando integralmente SEO, favicon e JSON-LD.
4. Rendere locali layout generici, tassonomie, 404, RSS e sitemap.
5. Migrare i campi `hugoblox` verso uno schema neutro e aggiornare generatori
   e controlli dei contenuti.
6. Rimuovere il modulo, `go.mod`, `go.sum` e la configurazione non più usata.
7. Ripetere audit funzionale, confronto visivo e controllo completo degli URL.

## Anomalia nota della baseline

Il tag `Crowd_Frame` compare anche come `crowd_frame`. Hugo conserva lo stesso
URL ma può scegliere una capitalizzazione diversa tra due build. La correzione
verrà effettuata nel passaggio dedicato alle tassonomie, fissando il titolo
pubblico senza cambiare le etichette presenti nelle pagine esistenti.
