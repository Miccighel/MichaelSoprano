# Controllo dei collegamenti esterni — 1 ottobre 2026

Comando: `ruby site/scripts/check-external-links.rb`, sui 413 URL esterni
unici del sito compilato. Nessuna risposta HTTP 404 rilevata.

Il controllo non è interamente verde: `https://ecir2026.eu/` non supera la
verifica TLS. Anche una seconda verifica con curl, senza disabilitare il
controllo del certificato, segnala un certificato non valido per il nome host.
Il link è presente nelle due pagine dei poster ECIR 2026. Resta invariato:
non è stato trovato un sostituto che superi entrambi i controlli di accesso e TLS.
La piattaforma Dryfta dell'evento è indicizzata, ma restituisce HTTP 500 alla
verifica diretta. Il problema richiede una correzione da parte del sito dell'evento.

Diversi domini (ACM, Scholar, Scopus, WoS, LinkedIn e collegamenti di condivisione)
restituiscono risposte di accesso limitato. Il checker le segnala come non
verificate, non come link validi o rotti. Non è stato disattivato alcun controllo
TLS e il controllo esterno resta manuale, fuori dal workflow di pubblicazione.

Questo controllo riguarda URL HTML esterni. I target del sito incorporati nei
CV PDF sono verificati separatamente dalla build; la disponibilità dei target
PDF esterni non è attestata da questo report.
