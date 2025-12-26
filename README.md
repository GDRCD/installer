# GDRCD Installer

**GDRCD Installer** è uno script batch progettato per semplificare l'installazione dell'ambiente di sviluppo per GDRCD su Windows. Questo strumento automatizza l'installazione di **MySQL 8.0**, **PHP 8.4** e **GDRCD**, configurando tutto il necessario per avviare il server di sviluppo con un solo click. 

## Requisiti

- **Sistema operativo**: Windows 10/11 (64-bit)
- **Privilegi**: Amministratore (richiesti automaticamente dallo script)
- **Connessione internet**: Necessaria per il download dei componenti

## Componenti installati

### MySQL 8.0
- Installato tramite **MySQL Installer** (via winget)
- Configurazione guidata per l'utente
- Creazione automatica di database e utente dedicato per GDRCD
- Installato come servizio Windows (avvio automatico)

### PHP 8.4
- Versione CLI ottimizzata per Windows
- Include tutte le estensioni necessarie
- Download automatico dall'ultima versione stabile
- Installato in: `C:\Program Files\GDRCD\php\8.4`

### GDRCD
- Download automatico dell'ultima versione da GitHub
- Installato in: `C:\Program Files\GDRCD\web`
- Configurazione database preimpostata

## Stato del progetto

Questo progetto è in fase **alpha** e pertanto non è ancora stabile e soggetto ad errori. 

### Funzionalità implementate
- Installazione automatica di MySQL, PHP e GDRCD
- Configurazione database automatica
- Gestione installazioni esistenti
- Interfaccia utente guidata
- Script di avvio webserver e collegamento desktop

## Contribuire

Ogni contributo è ben accetto!  Se riscontri problemi o hai suggerimenti: 

1. Apri una **Issue** descrivendo il problema o la feature richiesta
2. Invia una **Pull Request** con le tue modifiche
3. Segnala eventuali bug o comportamenti inattesi

### Aree dove contribuire

- 🐛 **Bug fixing**:  Risoluzione di problemi e comportamenti inattesi
- 📝 **Documentazione**: Miglioramento del README e della documentazione inline
- ✨ **Nuove funzionalità**: Implementazione di feature richieste dagli utenti
- 🧪 **Testing**: Test su diverse configurazioni Windows e segnalazione di edge cases

### Linee guida per il codice

- Mantieni lo stile di codifica esistente (batch file con commenti in italiano)
- Commenta le sezioni complesse del codice
- Testa le modifiche su un ambiente pulito prima di committare
