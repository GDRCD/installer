@echo OFF
chcp 1252 >nul
SETLOCAL ENABLEEXTENSIONS
SETLOCAL DISABLEDELAYEDEXPANSION


:::: Variabili di configurazione globale ::::

    set Version=v0.9.8

    :: Cartella dove si trova attualmente questo batch
    set InstallationFolder=%CD%

    :: Cartella di installazione dello stack
    set StackFolder=%InstallationFolder%\stack

    :: File di configurazione .env dello stack
    set EnvFile=%StackFolder%\.env

    :: Percorso di installazione di GDRCD
    set GdrcdFolder=%StackFolder%\www\GDRCD

    :: File di connessione al db di GDRCD ::
    set GdrcdOverrides=%GdrcdFolder%\core\db_overrides.php


:::: Logica di Business ::::

    :: schermata titoli
    call :TitleScreen

    :: chiedo il consenso dell'utente per l'installazione dei programmi necessari
    echo Procedendo, i seguenti programmi saranno installati sul tuo computer
    echo     WSL (Windows Subsystem for Linux)
    echo     Docker
    echo     Git
    echo.

    call :AskForUserConfirmation "Vuoi procedere con l'installazione dei programmi elencati?"

    echo.

    :: se l'utente ha dato il consenso installo i software necessari ::
    call :RequireWSLDependency
    call :RequireProgramDependency "Git" "git.exe" "Git.Git"
    call :RequireProgramDependency "Docker" "docker.exe" "Docker.DockerDesktop"

    echo.

    :: chiedo all'utente se vuole installare nella directory corrente
    echo Sto per scaricare una versione aggiornata di GDRCD/stack e GDRCD/GDRCD
    echo Cartella di installazione: %StackFolder%
    echo.

    :: TODO: scelta di una cartella alternativa
    call :AskForUserConfirmation "Sei sicuro di voler installare nella cartella indicata?"

    echo.

    :: uso git per scaricare lo stack
    call :GitClone %StackFolder% "GDRCD/stack"

    echo.

    :: uso git per scaricare GDRCD
    call :GitClone %GdrcdFolder% "GDRCD/GDRCD" "dev6"

    echo.

    :: genero il file .env precompilato per lo stack
    echo Procedo con la configurazione dello stack
    echo Creazione del file .env...
    call copy .\stack\sample.env %EnvFile%

    echo.
    echo Configurazione del file .env in corso...

    call :FileReplaceValue "PROJECT=" "PROJECT=gdrcd" %EnvFile%
    call :FileReplaceValue "MAILHOG_PORT=" "MAILHOG_PORT=8902" %EnvFile%
    call :FileReplaceValue "DB_PORT=" "DB_PORT=8903" %EnvFile%
    call :FileReplaceValue "PHP_VERSION=" "PHP_VERSION=php8" %EnvFile%
    call :FileReplaceValue "MYSQL_ROOT_PASSWORD=" "MYSQL_ROOT_PASSWORD=gdrcd" %EnvFile%
    call :FileReplaceValue "MYSQL_USER=" "MYSQL_USER=gdrcd" %EnvFile%
    call :FileReplaceValue "MYSQL_PASSWORD=" "MYSQL_PASSWORD=gdrcd" %EnvFile%
    call :FileReplaceValue "SERVICE_PORT=" "SERVICE_PORT=8900" %EnvFile%
    call :FileReplaceValue "PMA_PORT=" "PMA_PORT=8901" %EnvFile%
    call :FileReplaceValue "MYSQL_DATABASE=" "MYSQL_DATABASE=gdrcd" %EnvFile%

    echo.

    :: genero il file db_overrides.php di GDRCD
    echo Procedo con la configurazione dei parametri di connessione al database di GDRCD
    echo Creazione del file db_overrides.php...

    call copy %StackFolder%\www\GDRCD\core\db_config.php %GdrcdOverrides%

    echo.
    echo Configurazione del file db_overrides.php in corso...

    call :FileReplaceValue "'localhost'" "'gdrcd_database'" %GdrcdOverrides%

    echo.

    :: avvio il docker engine
    call docker desktop start

    echo.
    echo Attendi che la finestra di docker completi l'avvio prima di procedere
    echo.

    pause

    :: lancio la configurazione dello stack
    call :StackInstallAndStart

    :: avvio il browser di default con l'indirizzo del container dove gira GDRCD
    call :OpenDefaultBrowser "http://127.0.0.1:8900/GDRCD"

    :: termine programma
    goto Exit


:::: Funzioni ::::

    :: Apre il browser di default alla pagina indicata
    :OpenDefaultBrowser
        ::          %~1 [in] - URL
        start "" %~1
        exit /B 0

    :: Effettua il git clone del repository e si assicura di normalizzare l'uso del Line Feed per i files
    :GitClone
        ::          %~1 [in] - Repository cloning folder
        ::          %~2 [in] - Repository in the form of "vendor/package"
        ::          %~3 [in] - Optional - branch to checkout

        set RepoFolder=%~1
        set Repository=%~2
        set Branch=%~3

        :: uso git per scaricare lo stack
        echo Sto scaricando %Repository%...
        call git clone https://github.com/%Repository%.git %RepoFolder%

        cd %RepoFolder%

        :: Se indicato un particolare branch ne faccio il checkout
        if "%Branch%" neq "" (
            call git checkout -b %Branch% --track origin/%Branch%
        )

        :: normalizzo i line endings in LF perchè altrimenti si presentano problemi sotto WSL
        git config core.autocrlf false
        git config core.eol lf
        git ls-files -z >nul
        git checkout .

        cd %InstallationFolder%
        exit /B 0

    :: Si occupa di installare lo stack, buildare i container e avviarli
    :StackInstallAndStart
        :: no params
        :: no return
        cd %StackFolder%
        :: rimuove eventuali CarriageReturn nel file .env
        call wsl sed -i 's/\r//' .env
        :: installa, builda i container e li avvia
        call wsl sudo ./run install
        call wsl ./run build
        call wsl ./run start
        cd %InstallationFolder%
        exit /B 0

    :: Verifica la presenza di wsl configurato, in caso non lo fosse
    :: provvede all'installazione dell'ambiente di default
    :RequireWSLDependency
        :: no params
        :: no return
        call wsl --list > nul 2>&1

        IF %ERRORLEVEL% EQU 0 (
            echo WSL è già installato.
        ) ELSE (
            call wsl --install
            echo.
            echo WSL installato!
        )
        exit /B 0

    :: Verifica la presenza del file .exe di un dato programma
    :: se non trovato il programma viene installato tramite winget
    :RequireProgramDependency
        ::          %~1 [in] - Friendly name of the program
        ::          %~2 [in] - .exe program filename
        ::          %~3 [in] - exact winget id of the program

        set ProgramLabel=%~1
        set ProgramExe=%~2
        set ProgramWingetId=%~3
        for %%a in ("%ProgramExe%") do set ProgramFullPath=%%~$PATH:a

        if "%ProgramFullPath%"=="" (
            echo Procedo con l'installazione di "%ProgramLabel%"...
            call winget install -e --id %ProgramWingetId%
            echo.
            echo %ProgramLabel% installato!
        ) else (
            echo %ProgramLabel% già installato
        )
        exit /B 0

    :: Apre un prompt per chiedere all'utente conferma per una data operazione
    :: Se l'esito è negativo lo script viene terminato
    :AskForUserConfirmation
        ::          %~1 [in] - Custom question
        set QuestionText=%~1

        if "%QuestionText%"=="" (
            set /P UserAnswer="Confermi di voler proseguire? (Y/N) "
        ) else (
            set /P UserAnswer="%QuestionText% (Y/N) "
        )

        :: converto la scelta utente in uppercase
        set UserAnswer=%UserAnswer:~0,1%
        set UserAnswer=%UserAnswer:~0,1%

        if "%UserAnswer%" neq "Y" (
            if "%UserAnswer%" neq "y" (
                goto Exit
            )
        )
        exit /B 0

    :: Intestazione del programma
    :TitleScreen
        echo.
        echo """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
        echo "          ____ ____  ____   ____ ____    ___           _        _ _            %Version% "
        echo "         / ___|  _ \|  _ \ / ___|  _ \  |_ _|_ __  ___| |_ __ _| | | ___ _ __         "
        echo "        | |  _| | | | |_) | |   | | | |  | || '_ \/ __| __/ _` | | |/ _ \ '__|        "
        echo "        | |_| | |_| |  _ <| |___| |_| |  | || | | \__ \ || (_| | | |  __/ |           "
        echo "         \____|____/|_| \_\\____|____/  |___|_| |_|___/\__\__,_|_|_|\___|_|           "
        echo "                                                                   for Windows        "
        echo """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
        echo.
        exit /B 0

    :: Procedura di sostituzione valori in un file in puro batch
    :: Lo script è stato modificato per risolvere alcuni problemi rispetto alla sua versione originale
    :: source: https://www.dostips.com/DtCodeBatchFiles.php#Batch.FindAndReplace
    :FileReplaceValue
        ::          %~1 [in] - string to be replaced
        ::          %~2 [in] - string to replace with
        ::          %~3 [in] - file to be parsed

        if "%~1"=="" call findstr "^::" "%~f0"&GOTO:EOF

        set "tempFile=%~3.tmp"
        set "fileExt=%~x3"

        >"%tempFile%" (
            for /f "usebackq tokens=1,* delims=" %%a in ("%~3") do (
                set "line=%%a"
                SETLOCAL ENABLEDELAYEDEXPANSION

                rem Different handling based on file extension
                if /i "!fileExt!"==".env" (
                    rem For .env files - exact matches only
                    if "!line!"=="%~1" (
                        echo(%~2
                    ) else (
                        echo(!line!
                    )
                ) else (
                    rem For other files - substring replacement
                    set "modified=!line:%~1=%~2!"
                    echo(!modified!
                )

                ENDLOCAL
            )
        )

        call move /y "%tempFile%" "%~3" >nul
        exit /B %ERRORLEVEL%

    :Exit
        pause
        exit


:::: Fine ::::