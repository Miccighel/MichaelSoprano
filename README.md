# Sito personale di Michael Soprano

Repository privata del sito [michaelsoprano.com](https://michaelsoprano.com),
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
- `site/public/`, `site/resources/`, `site/static/vendor/`, `node_modules/` e
  le cache locali sono file generati: non vanno modificati né aggiunti a Git.
- I vecchi sorgenti sono conservati nel ramo `hugo-version`; lo snapshot del
  vecchio sito pubblicato è in `codex/legacy-gh-pages-2026-08-09`, mentre
  `codex/pre-hugo-pure-deploy-2026-08-24` conserva lo stato immediatamente
  precedente al passaggio in produzione di Hugo puro.
- Anche se la repository è privata, password, token e credenziali non devono
  essere salvati nei file versionati.

## Dove modificare cosa

| Cosa | File o cartella |
| --- | --- |
| Profilo, interessi, formazione, esperienza e link social | `site/data/home.yaml` |
| Bibliometria, attività accademica, premi e ordine della home | `site/content/_index.md` |
| Menu principale | `site/config/_default/menus.yaml` |
| Pubblicazioni | `site/content/publications/` |
| Presentazioni e poster | `site/content/events/` |
| Didattica e altri post | `site/content/blog/` |
| Immagine personale | `site/assets/media/authors/michael-soprano.jpg` |
| Favicon e immagine social predefinita | `site/assets/media/icon.png` e fallback `site/static/favicon.ico` |
| CV scaricabili | `site/static/media/CVs/` |
| Presentazioni, poster, tesi e altri download | `site/static/media/` |
| Risorse tecniche dell'interfaccia | `site/static/ui/` |
| Stile personalizzato | `site/assets/css/custom.css` |

## Preparazione dell'ambiente

Servono:

- Node.js 24;
- pnpm 10.14.0;
- Hugo Extended 0.165.0.

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

Le nuove pagine entrano automaticamente negli archivi e nelle raccolte della
homepage. Gli URL pubblici storici restano compatibili grazie alla
configurazione dei permalink.

## Aggiornare gli indicatori bibliometrici

Le cifre mostrate sul sito si trovano nella sezione `Bibliometrics` di
`site/content/_index.md`. Aggiornare insieme:

- numero di articoli;
- citazioni;
- h-index;
- data dell'ultimo aggiornamento.

Se gli stessi valori compaiono nei CV, aggiornare anche i sorgenti nella
repository sorella `../LaTeX` e rigenerare entrambi i PDF.

## Aggiornare i CV

Dalla repository LaTeX:

```bash
cd ../LaTeX
./build_all.sh --sync-website ../Website
```

Il comando compila le versioni italiana e inglese e copia i PDF direttamente
in `site/static/media/CVs/`. Prima del commit conviene aprire entrambi i file e
controllare data, metriche, impaginazione e numero di pagine.

## Anteprima locale

```bash
cd site
pnpm run vendor
./scripts/check-content.rb
hugo server --disableFastRender
```

L'indirizzo locale viene mostrato da Hugo, normalmente
`http://localhost:1313/`. Controllare almeno:

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
ruby site/scripts/check-external-links.rb
```

`pnpm run check` è il comando canonico usato anche dal workflow GitHub: prepara
gli asset locali, valida i sorgenti, compila Hugo, genera l'indice Pagefind e
controlla il sito risultante. Il controllo dei link esterni viene eseguito
automaticamente una volta alla settimana.

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

## Ripristino del vecchio sito

Il ripristino non richiede di riscrivere `master`:

1. aprire **Actions** su GitHub;
2. scegliere **Legacy rollback**;
3. avviare manualmente il workflow da `master`;
4. attendere il deploy `github-pages`;
5. verificare sito e dominio personalizzato.

La procedura dettagliata e i controlli per il record `CNAME` sono in
[`docs/ROLLBACK.md`](docs/ROLLBACK.md).

## Manutenzione periodica

- Aggiornare bibliometria e CV quando cambiano i dati.
- Controllare gli avvisi Dependabot e aggiornare una dipendenza alla volta.
- Dopo ogni aggiornamento di Hugo o delle dipendenze, rifare build, audit e
  controllo visivo completo.
- Font, icone e librerie dell'interfaccia sono ospitati localmente; la mappa
  OpenStreetMap viene caricata soltanto nella homepage.
- Il controllo settimanale dei link tratta come avvisi soltanto le catene TLS
  incomplete esplicitamente note; ogni altro errore continua a far fallire il
  workflow.
- Non eliminare `site/static/CNAME`, `site/assets/media/icon.png` o
  `site/static/favicon.ico`.
- Conservare i rami di rollback finché la nuova versione non è stabile da
  tempo sufficiente.
