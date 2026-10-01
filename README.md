# Sito personale di Michael Soprano

Sorgenti del sito [michaelsoprano.com](https://michaelsoprano.com),
realizzato con Hugo e pubblicato tramite GitHub Pages.

Questo README è il promemoria operativo per la manutenzione del sito. La
documentazione tecnica dell'applicazione Hugo si trova in
[`site/README.md`](site/README.md).

## Regole essenziali

- La sorgente attuale e canonica è tutta dentro `site/`.
- `master` è il ramo di produzione: ogni aggiornamento unito lì viene
  convalidato e poi pubblicato automaticamente.
- Le modifiche vanno preparate in un ramo separato e unite tramite pull
  request solo dopo il superamento del controllo **Validate and build**.
- `site/public/`, `site/resources/`, `site/static/vendor/`, `site/node_modules/` e
  le cache locali sono file generati: non vanno modificati né aggiunti a Git.
- La repository è pubblica: non salvare password, token o credenziali nei file
  versionati.

## Dove modificare cosa

| Cosa | File o cartella |
| --- | --- |
| Biografia, interessi, formazione e link social | `site/data/authors/michael-soprano.yaml` |
| Esperienza, visite, topics e limiti delle raccolte in home | `site/data/home.yaml` |
| Bibliometria (copia generata dai sorgenti CV) | `site/data/bibliometrics.json` |
| Attività accademica, premi e ordine della home | `site/content/_index.md` |
| Menu principale | `site/config/_default/menus.yaml` |
| Pubblicazioni | `site/content/publications/` |
| Presentazioni, poster e seminari divulgativi | `site/content/events/` |
| Didattica e altri post | `site/content/blog/` |
| Immagine personale | `site/assets/media/authors/michael-soprano.jpg` |
| Favicon e immagine social predefinita | `site/assets/media/icon.png` e fallback `site/static/favicon.ico` |
| CV scaricabili | `site/static/media/CVs/` |
| Presentazioni, poster, tesi e altri download | `site/static/media/` |
| Risorse tecniche dell'interfaccia (generate localmente) | `site/static/vendor/` |
| Fondazione visiva, token e accessibilità | `site/assets/css/design-system.css` |
| Compatibilità con la presentazione storica | `site/assets/css/custom.css` |

## Preparazione dell'ambiente

Servono:

- Node.js 24;
- pnpm 10.14.0;
- Hugo Extended 0.165.0;
- `pdfinfo` di Poppler, per controllare i link nei CV durante `pnpm run check`.

Gli script di validazione e build richiedono anche Ruby.
Su macOS, se `pdfinfo` manca, si può installare con `brew install poppler`.
Il workflow GitHub installa Poppler automaticamente.

La prima volta, o dopo un aggiornamento delle dipendenze:

```bash
cd site
pnpm install --frozen-lockfile
pnpm run vendor
```

`pnpm run vendor` prepara localmente font, icone e Leaflet nelle versioni
bloccate dal progetto.

## Aggiungere un contenuto

Dal percorso `site/`, usare uno dei generatori:

```bash
./scripts/new-content.rb publication titolo-del-paper
./scripts/new-content.rb event nome-conferenza-2027
./scripts/new-content.rb teaching nome-insegnamento
```

Ogni comando crea una cartella con un `index.md` già strutturato. Compilare i
campi, aggiungere nella stessa cartella eventuali immagini o allegati e
impostare `draft: false` quando il contenuto è pronto.

Per i titoli di pubblicazioni e presentazioni, conservare la grafia originale
del contributo (slide, poster o pubblicazione), incluse maiuscole, sigle e nomi
propri. Usare lo stesso titolo nel sito e nei CV; non applicare trasformazioni
automatiche in title case. Esempio: `A Caccia di Fake News`.

La homepage mostra fino a 15 pubblicazioni e 15 presentazioni, con accesso agli
archivi completi. I limiti sono configurati in `site/data/home.yaml`, tramite
`publications.homepage_limit` e `presentations.homepage_limit`.

Una volta impostato `draft: false`, le nuove pagine principali entrano automaticamente
negli archivi e nelle raccolte della homepage. Gli URL pubblici storici
restano compatibili grazie alla configurazione dei permalink.

Per una nuova edizione di un insegnamento, mantenere il programma generale nella
pagina principale e creare una pagina annuale in `site/content/blog/` con
`course_parent` (URL della pagina principale), `course_edition` (per esempio
`2026/2027`), `course_hidden: true` e un `url` stabile nella forma
`/post/<corso>/2026-2027/`. La pagina annuale compare automaticamente nel
selettore degli anni del corso, ma non come corso indipendente nella homepage o
nell'archivio Teaching. Lasciare tag e categoria sulla sola pagina principale,
per non moltiplicare artificialmente i conteggi dei Topics. Separare contenuti
e ore che variano per anno; non attribuire retroattivamente un nuovo programma
alle edizioni precedenti.

Per un evento di cui si conosce la data ma non l'orario, usare date nel formato
`YYYY-MM-DD` e `event_time_unknown: true`. Questo nasconde gli orari senza
descrivere il contributo come un evento di un'intera giornata. L'eventuale durata
confermata può essere riportata nel testo della pagina.

## Aggiornare gli indicatori bibliometrici

La fonte unica è `../LaTeX/data/bibliometrics.json`. La copia nel sito è
generata: non modificarla manualmente. Per ogni fonte aggiornare insieme:

- numero di pubblicazioni;
- citazioni;
- h-index;
- i10-index, quando disponibile.

Aggiornare anche `checked_on`, `last_updated` e `last_updated_it` con la stessa
data dell'ultimo aggiornamento. Ogni fonte conserva anche il proprio
`checked_on`: se non è accessibile, lascia invariati valori e data di verifica.
Il sito e i CV segnalano le fonti con una verifica meno recente.

Per Google Scholar conservare una rilevazione completa in
`../LaTeX/data/scholar-citations-YYYY-MM-DD.json`, senza sostituire quelle
precedenti. Il file contiene `checked_on`, `source`, `profile_id`,
`citation_counts_by_article_id` (anche gli zeri) e `article_titles`.
Usare gli ID degli articoli, non la posizione nell'elenco. Il totale deve
corrispondere alle metriche Scholar della stessa data.

La sincronizzazione genera `site/data/citation-history.json`: confronta
le rilevazioni consecutive della stessa fonte, include aumenti e diminuzioni,
e distingue articoli aggiunti o rimossi. Il riepilogo è disponibile sotto
la tabella delle metriche, in “Latest citation changes”. Sono differenze tra
rilevazioni, non date di pubblicazione delle citazioni. La raccolta resta
manuale: il confronto e la presentazione sono automatici, non lo scraping.

La pagina `/citation-history/` usa `site/data/citation-series.json`, generato
dalla stessa sincronizzazione. Mostra la somma cumulata delle citazioni annuali di Scholar.
Il grafico mostra una linea per paper,
evidenziabile passando sul titolo o sulla linea; i tooltip dei punti mostrano cumulato,
anno e conteggio annuale, anche con tastiera o tocco. La legenda permette di cercare
un titolo, ordinare alfabeticamente o per cumulato crescente/decrescente,
mantenere evidenziata la sua linea e ripristinare la vista completa.
Il grafico ha un solo ingresso con Tab: frecce sinistra/destra per gli anni,
su/giù per i paper, Home/End per gli estremi, Enter per la selezione ed Escape
per chiudere il tooltip. Tab permette sempre di proseguire ai controlli successivi.
La somma non viene corretta per coincidere con il totale del profilo, che può differire.
I valori recuperati dai CV sono in `../LaTeX/data/bibliometrics-history.json`,
con data del documento e commit di provenienza. Quelli annuali si conservano
in `../LaTeX/data/scholar-annual-YYYY-MM-DD.json`: sono una lettura attuale
dell'indicizzazione per anno, non vecchie rilevazioni. Gli anni assenti non
vengono riempiti con zeri; l'anno corrente è parziale.
La generazione conserva anche i totali correnti nell'archivio per non perderli
all'aggiornamento successivo. Non modificare a mano gli esportati del sito.

Eseguire il comando di sincronizzazione qui sotto: genera la bibliometria
LaTeX, compila entrambi i CV e copia dati e PDF nel sito, senza commit o deploy.

## Aggiornare i CV

Dalla cartella principale di questa repository:

```bash
cd ../LaTeX
./build_all.sh --sync-website ../Website
```

Il comando compila le versioni italiana e inglese e copia i PDF direttamente
in `site/static/media/CVs/`, insieme a `site/data/bibliometrics.json`,
`site/data/citation-history.json`, `site/data/citation-series.json` e al
manifest di integrità `site/data/cv-sync.json`. La build del sito controlla
le impronte SHA-256: un PDF o un dato modificato fuori dalla sincronizzazione
blocca la build. Non serve accedere all'altra repository durante il deploy.
Questo verifica la coerenza dell'esportazione, non la correttezza delle
metriche sui servizi esterni. Prima del commit conviene aprire entrambi i file e
controllare data, metriche, impaginazione e numero di pagine.
Se cambiano i sorgenti dei CV, pubblicare prima la relativa pull request nella
repository LaTeX (ramo `main`), poi quella del sito (ramo `master`) con i PDF
sincronizzati. La build del sito non ricompila i CV.

## Controllare le citazioni BibTeX

`node site/scripts/audit-bibliography.mjs` confronta i file `cite.bib` delle
pubblicazioni con `../LaTeX/bibliography.bib`; aggiungendo `--crossref` confronta
anche i metadati pubblici associati ai DOI. Produce JSON senza modificare i
file. Le differenze sono candidati da verificare, non errori da correggere
automaticamente: nomi composti, numeri di articolo e date online o del fascicolo
richiedono interpretazione. Il controllo di rete non fa parte della build.
Il report iniziale e i suoi limiti sono in
[`docs/BIBLIOGRAPHY-REVIEW-2026-10-01.md`](docs/BIBLIOGRAPHY-REVIEW-2026-10-01.md).

La finestra Cite evidenzia la sintassi con elementi di testo sicuri; copia e
download mantengono il BibTeX originale, senza cambiare i metadati.

## Modulo di contatto

Il modulo usa un POST HTML diretto a Formspree (`mjvpnjeb`), sia in locale
sia in produzione. Dopo l'invio, Formspree gestisce la conferma e l'eventuale
CAPTCHA configurato nel suo pannello. I campi obbligatori e il campo anti-spam
`_gotcha` funzionano anche senza JavaScript.

Se l'invio fallisce soltanto dal dominio pubblico, controllare nel pannello
Formspree l'eventuale impostazione **Restrict to Domain**: il valore corretto
è `michaelsoprano.com`, senza protocollo e senza `www`. Verificare anche
l'attivazione del modulo, la destinazione email e i limiti dell'account.
Per il collaudo completo dopo il deploy, inviare un messaggio dal sito pubblico,
completare l'eventuale CAPTCHA e verificare la ricezione nella casella destinataria;
la sola build non dimostra la consegna dell'email.

## Anteprima locale

```bash
cd site
pnpm run vendor
./scripts/check-content.rb
hugo server --disableFastRender
```

L'indirizzo locale viene mostrato da Hugo, normalmente
`http://localhost:1313/`. Per verificare anche la ricerca con un indice aggiornato,
eseguire `pnpm run check` e servire la cartella `public/`: Hugo server non
rigenera l'indice Pagefind. Controllare almeno:

- homepage e menu desktop/mobile;
- ricerca;
- archivi e pagine interne di pubblicazioni, eventi e didattica;
- download dei due CV;
- favicon nella scheda del browser;
- tema chiaro e scuro.

## Controllo completo prima della pull request

```bash
cd site
pnpm install --frozen-lockfile
pnpm run check
```

Facoltativamente, per controllare anche i collegamenti esterni:

```bash
ruby scripts/check-external-links.rb
```

`pnpm run check` è il comando canonico usato anche dal workflow GitHub: prepara
gli asset locali, valida i sorgenti, compila Hugo, genera l'indice Pagefind e
controlla il sito risultante. Legge inoltre i collegamenti incorporati nei due
PDF dei CV e verifica che quelli verso `michaelsoprano.com` corrispondano a
risorse locali, rispettando le maiuscole dei percorsi. Il controllo usa
`pdfinfo` (Poppler). I link verso altri domini non sono verificati in questo
passaggio; il controllo dei link esterni delle pagine HTML resta facoltativo e
manuale, fuori dal workflow GitHub.

La tipografia usa due scale condivise per metadati (`.875rem`) ed etichette
accessorie (`.75rem`), e una dimensione di base in `rem` che rispetta le
preferenze del browser. Gli annunci del grafico sono esposti tramite una
regione live non visibile, senza reintrodurre note nella pagina.

La build esegue anche `scripts/test-interactions.mjs`: test DOM con jsdom per
menu mobile e dropdown, ricerca (con il caricamento di Pagefind simulato),
filtri e interazioni del grafico. Non sostituiscono un controllo nel browser:
geometria, contrasto, touch e funzionamento dell'indice Pagefind reale restano
da verificare in anteprima. Non introducono dipendenze nel sito pubblicato.

## Pubblicazione

1. Creare un ramo di lavoro con prefisso `codex/` o un altro nome descrittivo.
2. Fare commit e push delle modifiche.
3. Aprire una pull request verso `master`.
4. Attendere che **Website / Validate and build** sia verde.
5. Controllare l'artefatto `site-preview`, se serve un'ultima verifica.
6. Unire la pull request: il deploy su GitHub Pages parte automaticamente.
7. Verificare homepage, ricerca, CV, pagine interne, favicon e dominio
   `michaelsoprano.com`.

Solo un push a `master` può avviare il normale deploy di produzione. I branch
di lavoro e le pull request non modificano il sito pubblico.

Le procedure di ripristino, i riferimenti ai rami storici e i controlli del
dominio sono in [`docs/ROLLBACK.md`](docs/ROLLBACK.md).

## Manutenzione periodica

- Aggiornare bibliometria e CV quando cambiano i dati.
- Controllare gli avvisi Dependabot e aggiornare una dipendenza alla volta.
- Dopo ogni aggiornamento di Hugo o delle dipendenze, rifare build, audit e
  controllo visivo completo.
- Non eliminare `site/static/CNAME`, `site/assets/media/icon.png` o
  `site/static/favicon.ico`.
