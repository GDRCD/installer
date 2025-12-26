@echo OFF
chcp 1252 >nul
SETLOCAL ENABLEEXTENSIONS
SETLOCAL ENABLEDELAYEDEXPANSION

:::: Variabili di configurazione globale ::::  

    set SoftwareName=GDRCD Installer
    set Version=v1.0.0

    :: Cartella di installazione principale in Program Files
    set InstallationFolder=%ProgramFiles%\GDRCD

    :: Cartella per PHP
    set PhpFolder=%InstallationFolder%\php\8.4

    :: Cartella per GDRCD web
    set WebFolder=%InstallationFolder%\web

    :: Cartella per MySQL (se installato manualmente)
    set MysqlFolder=%InstallationFolder%\mysql

    :: Cartella MySQL effettiva (sarà impostata durante l'installazione)
    set MysqlBinFolder=

    :: File marker per verificare l'installazione
    set InstallMarker=%InstallationFolder%\.installed

    :: File batch di avvio
    set StartBatchFile=%InstallationFolder%\gdrcd-start.bat

    :: Porta MySQL
    set MysqlPort=3306

    :: Password root MySQL (configurare in caso di installazione di MySQL esistente)
    set MysqlRootPassword=

    :: MySQL user
    set MysqlUser=gdrcd

    :: MySQL user password
    set MysqlUserPassword=gdrcd

    :: Database name
    set MysqlDatabase=gdrcd

    :: Porta del webserver PHP
    set WebServerPort=8900

    :: URL per l'API di PHP
    set PhpApiUrl=https://dl.static-php.dev/static-php-cli/windows/spc-max/?format=json

    :: URL per l'API di GitHub releases
    set GdrcdApiUrl=https://api.github.com/repos/GDRCD/GDRCD/releases/latest

    :: File temporanei per i log delle operazioni
    set MysqlInstallLog=%TEMP%\gdrcd_mysql_install.log
    set PhpDownloadLog=%TEMP%\gdrcd_php_download.log
    set GdrcdDownloadLog=%TEMP%\gdrcd_download.log

    title %SoftwareName% %Version%

:::: Verifica privilegi amministrativi :::: 

    ::  Detect if already elevated by checking for a marker parameter
    if "%1"=="elevated" goto :ProgramStart

    :: Check if running as administrator
    net session >nul 2>&1
    
    if %ERRORLEVEL% NEQ 0 (
        
        call :TitleScreen
        echo.
        echo Questo script richiede i privilegi di amministratore. 
        echo. 
        echo Premere un tasto per riavviare lo script con privilegi elevati... 
        echo Oppure chiudi questa finestra per annullare.
        echo.
        pause >nul
        
        ::  Try to elevate with marker parameter
        powershell -Command "Start-Process -FilePath '%~f0' -ArgumentList 'elevated' -Verb RunAs"
        
        ::  Exit the non-elevated instance
        exit /B 0
    )

:::: Logica di Business ::::
    :ProgramStart

        :: schermata titoli
        call :TitleScreen

        :: verifica se l'ambiente è già installato
        if exist "%InstallMarker%" (
            echo.     
            echo L'ambiente GDRCD è già installato in: %InstallationFolder%
            echo.  
            echo Per reinstallare, elimina la cartella "%InstallationFolder%" ed esegui nuovamente questo script.  
            echo.  
            goto Exit
        )

        :: chiedo il consenso dell'utente per l'installazione
        echo Procedendo, i seguenti componenti saranno installati:  
        echo     MySQL 8.0
        echo     PHP 8.4 CLI
        echo     GDRCD (ultima versione)
        echo. 
        echo Cartella di installazione: %InstallationFolder%
        echo.    

        call :AskForUserConfirmation "Vuoi procedere all'installazione?"

        echo.  

        :: creo la struttura delle cartelle
        title %SoftwareName% %Version% - FASE 1/5

        echo. 
        call :PrintHeader "FASE 1/5: Preparazione ambiente" "INFO"
        echo. 
        echo Creazione struttura cartelle...
        if not exist "%InstallationFolder%" mkdir "%InstallationFolder%"
        if not exist "%PhpFolder%" mkdir "%PhpFolder%"
        if not exist "%WebFolder%" mkdir "%WebFolder%"
        echo Struttura cartelle creata con successo!

        echo. 

        :: download e installazione MySQL 8.0
        title %SoftwareName% %Version% - FASE 2/5

        echo. 
        call :PrintHeader "FASE 2/5: Installazione MySQL 8.0" "INFO"
        echo. 
        echo Apertura finestra di installazione MySQL...
        echo Attendi il completamento d^ell'installazione nella finestra separata.
        echo.
        
        call :DownloadAndInstallMysql

        echo.

        :: download e installazione PHP 8.4
        title %SoftwareName% %Version% - FASE 3/5

        echo.
        call :PrintHeader "FASE 3/5: Download e installazione PHP 8.4" "INFO"
        echo.
        echo Apertura finestra di download PHP...
        echo Attendi il completamento d^el download nella finestra separata. 
        echo.
        
        call :DownloadAndInstallPhp

        echo.

        :: download e installazione GDRCD
        title %SoftwareName% %Version% - FASE 4/5

        echo.
        call :PrintHeader "FASE 4/5: Download e installazione GDRCD" "INFO"
        echo.
        echo Apertura finestra di download GDRCD...
        echo Attendi il completamento del download nella finestra separata.
        echo.
        
        call :DownloadAndInstallGdrcd

        echo.  

        :: configurazione MySQL e script di avvio webserver
        title %SoftwareName% %Version% - FASE 5/5

        echo.
        call :PrintHeader "FASE 5/5: Configurazione finale" "INFO"
        echo.
        
        call :ConfigureMysql

        echo. 

        echo Creazione script di avvio... 
        call :CreateStartScript
        echo Script di avvio creato! 

        echo.

        echo Creazione collegamento desktop...
        call :CreateDesktopShortcut
        echo Collegamento creato!

        echo.  

        :: creo il marker di installazione completata
        title %SoftwareName% %Version% - OK

        echo Installazione completata > "%InstallMarker%"

        echo.
        call :PrintHeader "INSTALLAZIONE COMPLETATA ^CON SUCCESSO!" "SUCCESS"
        echo.   
        echo Dettagli installazione:  
        echo   - MySQL 8.0: Installato e configurato
        echo   - PHP 8.4: %PhpFolder%
        echo   - GDRCD:  %WebFolder%
        echo. 
        echo Credenziali database:
        echo   - Host: localhost
        echo   - Porta: %MysqlPort%
        echo   - Database: %MysqlDatabase%
        echo   - Username: %MysqlUser%
        echo   - Password: %MysqlUserPassword%
        echo   - Root password: %MysqlRootPassword%
        echo.  
        echo Per avviare il server web GDRCD:   
        echo   - Doppio click su "Avvia GDRCD" sul desktop
        echo   - Oppure esegui:  "%StartBatchFile%"
        echo.  
        echo Il server sarà accessibile su: http://localhost:%WebServerPort%
        echo.
        call :PrintHeaderLine
        echo.  

        :: Termine programma
        goto Exit


:::: Funzioni ::::

    :: Crea lo script batch di avvio del webserver
    :CreateStartScript
        :: no params
        :: no return

        :: Creo il file batch
        (
            echo @echo OFF
            echo chcp 1252 ^>nul
            echo.   
            call :SubPrintHeader "                                GDRCD Web Server"
            echo echo.  
            echo echo Avvio del server web GDRCD in corso...
            echo echo. 
            echo echo Server URL: http://localhost:%WebServerPort%
            echo echo Cartella web: %WebFolder%
            echo echo. 
            echo echo Premi CTRL+C per fermare il server
            call :SubPrintHeaderLine
            echo echo.  
            echo.   
            echo "%PhpFolder%\php. exe" -S localhost:%WebServerPort% -t "%WebFolder%"
            echo.  
            echo pause
        ) > "%StartBatchFile%"

        exit /B 0

    :: Crea un collegamento sul desktop
    :CreateDesktopShortcut
        :: no params
        :: no return

        :: Uso PowerShell per creare il collegamento
        powershell -Command "& {$WshShell = New-Object -ComObject WScript.Shell; $Desktop = $WshShell.SpecialFolders('Desktop'); $Shortcut = $WshShell.CreateShortcut($Desktop + '\Avvia GDRCD.lnk'); $Shortcut.TargetPath = '%StartBatchFile%'; $Shortcut.WorkingDirectory = '%InstallationFolder%'; $Shortcut.Description = 'Avvia il server web GDRCD'; $Shortcut.Save()}" >nul 2>&1

        exit /B 0

    :: Download e installazione di MySQL 8.0
    :DownloadAndInstallMysql
        :: no params
        :: no return
        
        :: Verifico se MySQL è già installato
        call :FindMysqlInstallation
        
        if defined MysqlBinFolder (
            echo MySQL e' gia' installato in: %MysqlBinFolder%
            echo Utilizzo installazione esistente. 
            echo. 
            exit /B 0
        )

        ::  Creo uno script temporaneo per l'installazione
        set TempInstallScript=%TEMP%\gdrcd_mysql_install.bat
        
        (
            echo @echo OFF
            echo chcp 1252 ^>nul
            call :SubPrintHeader "Installazione MySQL 8.0 in corso..." "INFO"
            echo echo. 
            echo echo Questo potrebbe richiedere alcuni minuti. 
            echo echo Attendi il completamento... 
            echo echo.
            echo winget install -e --id Oracle.MySQL -v "8.0.43" --silent --accept-package-agreements --accept-source-agreements
            echo. 
            echo if %%ERRORLEVEL%% EQU 0 ^(
            echo     echo. 
            
            echo    if exist "%ProgramFiles(x86)%\MySQL\MySQL Installer for Windows\MySQLInstaller.exe" ^(
            echo        start "" "%ProgramFiles(x86)%\MySQL\MySQL Installer for Windows\MySQLInstaller.exe"
            echo    ^) else if exist "%ProgramFiles%\MySQL\MySQL Installer for Windows\MySQLInstaller.exe" ^(
            echo        start "" "%ProgramFiles%\MySQL\MySQL Installer for Windows\MySQLInstaller.exe"
            echo    ^) else ^(
            echo        echo.
            echo        echo MySQL Installer non trovato nelle posizioni standard. 
            echo        echo Cerca "MySQL Installer" nel menu Start. 
            echo    ^)
            
            echo echo.
            call :SubPrintHeader "Completa l'installazione di MySQL" "INFO"
            echo echo.
            
            echo echo Una volta completata l'installazione di MySQL Server,
            echo echo premi un tasto per continuare con l'installazione di GDRCD... 
            echo echo.
            echo pause
            
            call :SubPrintHeader "MySQL installato ^con successo!" "SUCCESS"
            echo     echo SUCCESS ^> "%MysqlInstallLog%"
            echo ^) else ^(
            echo     echo. 
            call :SubPrintHeader "ERRORE durante l'installazione di MySQL" "ERROR"
            echo     echo FAILED ^> "%MysqlInstallLog%"
            echo ^)
            echo.
            echo echo. 
            echo echo Premi un tasto per chiudere questa finestra... 
            echo pause ^>nul
        ) > "%TempInstallScript%"

        :: Eseguo lo script in una nuova finestra e attendo
        start "Installazione MySQL" /wait cmd /c "%TempInstallScript%"

        :: Verifico il risultato
        if exist "%MysqlInstallLog%" (
            findstr /C:"SUCCESS" "%MysqlInstallLog%" >nul 2>&1
            if ! ERRORLEVEL! EQU 0 (
                call :PrintHeader "MySQL installato ^con successo!" "SUCCESS"
                del "%MysqlInstallLog%" >nul 2>&1
                del "%TempInstallScript%" >nul 2>&1
                
                ::  Attendo e trovo MySQL
                timeout /t 3 /nobreak >nul
                call :FindMysqlInstallation
                exit /B 0
            )
        )

        echo.
        call :PrintHeader "ERRORE durante l'installazione di MySQL" "ERROR"
        del "%MysqlInstallLog%" >nul 2>&1
        del "%TempInstallScript%" >nul 2>&1
        pause
        goto Exit

    :: Trova l'installazione di MySQL nel sistema
    :FindMysqlInstallation
        :: no params
        :: sets MysqlBinFolder

        :: Controlla se mysql.exe è nel PATH
        for %%a in ("mysql.exe") do set "MysqlBinFolder=%%~$PATH:a"
        
        :: Rimuovo il trailing backslash
        if defined MysqlBinFolder (
            set "MysqlBinFolder=!MysqlBinFolder:~0,-1!"
            exit /B 0
        )

        :: Controlla le posizioni comuni di installazione
        if exist "%ProgramFiles%\MySQL\MySQL Server 8.0\bin\mysql.exe" (
            set "MysqlBinFolder=%ProgramFiles%\MySQL\MySQL Server 8.0\bin"
            exit /B 0
        )

        if exist "%ProgramFiles%\MySQL\MySQL Server 8.4\bin\mysql.exe" (
            set "MysqlBinFolder=%ProgramFiles%\MySQL\MySQL Server 8.4\bin"
            exit /B 0
        )
        
        if exist "%MysqlFolder%\bin\mysql.exe" (
            set "MysqlBinFolder=%MysqlFolder%\bin"
            exit /B 0
        )

        :: MySQL non trovato
        set "MysqlBinFolder="
        exit /B 1
        
    :: Configurazione di MySQL
    :ConfigureMysql
        :: no params
        :: no return

        echo Configurazione MySQL...  

        :: Trovo MySQL se non già trovato
        if not defined MysqlBinFolder (
            call :FindMysqlInstallation
        )

        if not defined MysqlBinFolder (
            echo.   
            call :PrintHeader "ERRORE: MySQL non trovato nel sistema!" "ERROR"
            echo. 
            echo Verifica che MySQL sia stato installato correttamente.
            pause
            goto Exit
        )

        echo MySQL trovato in: %MysqlBinFolder%

        :: Verifico se il servizio MySQL è già in esecuzione
        sc query MySQL >nul 2>&1
        if %ERRORLEVEL% EQU 0 (
            echo Avvio servizio MySQL... 
            net start MySQL >nul 2>&1
            timeout /t 5 /nobreak >nul
        ) else (
            sc query MySQL80 >nul 2>&1
            if %ERRORLEVEL% EQU 0 (
                echo Avvio servizio MySQL80...
                net start MySQL80 >nul 2>&1
                timeout /t 5 /nobreak >nul
            ) else (
                sc query MySQL84 >nul 2>&1
                if %ERRORLEVEL% EQU 0 (
                    echo Avvio servizio MySQL84...
                    net start MySQL84 >nul 2>&1
                    timeout /t 5 /nobreak >nul
                ) else (
                    call :PrintHeader "ATTENZIONE: Servizio MySQL non trovato" "ERROR"
                    pause
                    goto Exit
                )
            )
        )

        echo Configurazione database e utenti... 
        echo. 

        :: Tento di connettermi come root senza password
        "%MysqlBinFolder%\mysql. exe" -u root --skip-password -e "SELECT 1" >nul 2>&1
        
        if %ERRORLEVEL% EQU 0 (
            :: Nuova installazione - nessuna password root
            echo Rilevata nuova installazione MySQL (nessuna password root).
            echo Configurazione in corso...
            "%MysqlBinFolder%\mysql.exe" -u root --skip-password -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '%MysqlRootPassword%'; CREATE DATABASE IF NOT EXISTS %MysqlDatabase%; CREATE USER IF NOT EXISTS '%MysqlUser%'@'localhost' IDENTIFIED BY '%MysqlUserPassword%'; GRANT ALL PRIVILEGES ON %MysqlDatabase%.* TO '%MysqlUser%'@'localhost'; FLUSH PRIVILEGES;" >nul 2>&1
            
            if ! ERRORLEVEL! EQU 0 (
                call :PrintHeader "MySQL configurato ^con successo!" "SUCCESS"
                exit /B 0
            ) else (
                call :PrintHeader "ERRORE durante la configurazione di MySQL." "ERROR"
                pause
                goto Exit
            )
        )

        :: Provo con la password predefinita dello script
        "%MysqlBinFolder%\mysql.exe" -u root -p%MysqlRootPassword% -e "SELECT 1" >nul 2>&1
        
        if %ERRORLEVEL% EQU 0 (
            :: Password corrisponde a quella dello script
            echo MySQL ha gia' la password configurata dallo script.
            echo Aggiornamento configurazione...
            "%MysqlBinFolder%\mysql.exe" -u root -p%MysqlRootPassword% -e "CREATE DATABASE IF NOT EXISTS %MysqlDatabase%; CREATE USER IF NOT EXISTS '%MysqlUser%'@'localhost' IDENTIFIED BY '%MysqlUserPassword%'; GRANT ALL PRIVILEGES ON %MysqlDatabase%.* TO '%MysqlUser%'@'localhost'; FLUSH PRIVILEGES;" >nul 2>&1
            
            if ! ERRORLEVEL! EQU 0 (
                call :PrintHeader "Database configurato ^con successo!" "SUCCESS"
                exit /B 0
            ) else (
                call :PrintHeader "ERRORE nella configurazione d^el database." "ERROR"
                pause
            )
            exit /B 0
        )

        :: La password root è diversa - chiedo all'utente
        echo. 
        call :PrintHeader "MySQL ha già una password root configurata." "INFO"
        echo.
        echo Per configurare il database GDRCD è necessaria la password di root.
        echo.
        
        set /P ExistingRootPassword="Inserisci la password di root di MySQL: "
        
        if "!ExistingRootPassword!"=="" (
            echo. 
            call :PrintHeader "Password non inserita. Configurazione annullata." "ERROR"
            goto Exit
        )

        :: Verifico la password inserita
        "%MysqlBinFolder%\mysql.exe" -u root -p!ExistingRootPassword!  -e "SELECT 1" >nul 2>&1
        
        if ! ERRORLEVEL! EQU 0 (
            echo. 
            echo Password corretta! Configurazione in corso...
            "%MysqlBinFolder%\mysql.exe" -u root -p!ExistingRootPassword! -e "CREATE DATABASE IF NOT EXISTS %MysqlDatabase%; CREATE USER IF NOT EXISTS '%MysqlUser%'@'localhost' IDENTIFIED BY '%MysqlUserPassword%'; GRANT ALL PRIVILEGES ON %MysqlDatabase%.* TO '%MysqlUser%'@'localhost'; FLUSH PRIVILEGES;" >nul 2>&1
            
            if ! ERRORLEVEL! EQU 0 (
                echo. 
                call :PrintHeader "MySQL configurato ^con successo!" "SUCCESS"
                echo.
                echo NOTA: La password di root di MySQL rimane quella esistente.
                echo       Per GDRCD usa le credenziali:  %MysqlUser% / %MysqlUserPassword%
                echo.
                exit /B 0
            ) else (
                echo.
                call :PrintHeader "ERRORE durante la configurazione d^el database." "ERROR"
                echo Verifica i permessi di root. 
                pause
                goto Exit
            )
        ) else (
            echo.
            call :PrintHeader "ERRORE: Password non corretta!" "ERROR"
            echo.
            echo Opzioni:
            echo 1. Ri-esegui lo script e inserisci la password corretta
            echo 2. Configura manualmente il database con questi comandi:
            echo. 
            echo    CREATE DATABASE IF NOT EXISTS %MysqlDatabase%;
            echo    CREATE USER IF NOT EXISTS '%MysqlUser%'@'localhost' IDENTIFIED BY '%MysqlUserPassword%';
            echo    GRANT ALL PRIVILEGES ON %MysqlDatabase%.* TO '%MysqlUser%'@'localhost';
            echo    FLUSH PRIVILEGES;
            echo.
            pause
            goto Exit
        )

        exit /B 0

    :: Download e installazione di PHP 8.4
    :DownloadAndInstallPhp
        :: no params
        :: no return

        :: Creo uno script temporaneo per il download
        set TempPhpScript=%TEMP%\gdrcd_php_download.bat
        
        (
            echo @echo OFF
            echo chcp 1252 ^>nul
            call :SubPrintHeader "Download PHP 8.4 in corso..." "INFO"
            echo echo.
            
            echo powershell -Command "& {$ErrorActionPreference='Stop'; try { $json = Invoke-RestMethod -Uri '%PhpApiUrl%'; $asset = $json | Where-Object { $_.name -match '^php-8\.4.*-cli-win\.zip$' } | Sort-Object -Property name -Descending | Select-Object -First 1; if ($asset) { Write-Host ('Trovata versione: ' + $asset.name); $downloadUrl = 'https://dl.static-php.dev' + $asset.full_path; Write-Host ('URL di download: ' + $downloadUrl); Invoke-WebRequest -Uri $downloadUrl -OutFile '%TEMP%\\php84.zip'; Write-Host 'Download completato' } else { Write-Error 'Versione PHP 8.4 CLI non trovata'; exit 1 } } catch { Write-Error ('Errore:  ' + $_.Exception.Message); exit 1 } }"

            echo if %%ERRORLEVEL%% EQU 0 ^(
            echo     echo. 
            echo     echo Estrazione PHP in corso...
            echo     powershell -Command "& {Expand-Archive -Path '%TEMP%\\php84.zip' -DestinationPath '%PhpFolder%' -Force}"
            echo     del "%TEMP%\\php84.zip" ^>nul 2^>^&1
            echo     echo. 
            call :SubPrintHeader "PHP 8.4 installato ^con successo!" "SUCCESS"
            echo     echo SUCCESS ^> "%PhpDownloadLog%"
            echo     timeout /t 3 /nobreak >nul
            echo ^) else ^(
            echo     echo.
            call :SubPrintHeader "ERRORE durante il download di PHP" "ERROR"
            echo     echo FAILED ^> "%PhpDownloadLog%"
            echo     echo.
            echo     echo Premi un tasto per chiudere questa finestra... 
            echo     pause ^>nul
            echo ^)
            echo.
        ) > "%TempPhpScript%"

        ::  Eseguo lo script in una nuova finestra e attendo
        start "Download PHP 8.4" /wait cmd /c "%TempPhpScript%"

        ::  Verifico il risultato
        if exist "%PhpDownloadLog%" (
            findstr /C:"SUCCESS" "%PhpDownloadLog%" >nul 2>&1
            if !ERRORLEVEL! EQU 0 (
                echo PHP 8.4 installato con successo!
                del "%PhpDownloadLog%" >nul 2>&1
                del "%TempPhpScript%" >nul 2>&1
                exit /B 0
            )
        )

        echo.
        call :PrintHeader "ERRORE: Download/Installazione PHP fallita!" "ERROR"
        del "%PhpDownloadLog%" >nul 2>&1
        del "%TempPhpScript%" >nul 2>&1
        pause
        goto Exit

    :: Download e installazione di GDRCD
    :DownloadAndInstallGdrcd
        :: no params
        :: no return

        :: Creo uno script temporaneo per il download
        set TempGdrcdScript=%TEMP%\gdrcd_gdrcd_download.bat
        
        (
            echo @echo OFF
            echo chcp 1252 ^>nul
            call :SubPrintHeader "Download GDRCD in corso..." "INFO"
            echo echo.
            echo powershell -Command "& {$ErrorActionPreference='Stop'; $release = Invoke-RestMethod -Uri '%GdrcdApiUrl%'; Write-Host ('Versione trovata: ' + $release.tag_name^); Write-Host 'Download in corso...'; Invoke-WebRequest -Uri $release.zipball_url -OutFile '%TEMP%\\gdrcd.zip'; Write-Host 'Download completato!'}"
            echo if %%ERRORLEVEL%% EQU 0 ^(
            echo     echo. 
            echo     echo Estrazione GDRCD in corso...
            echo     powershell -Command "& {Expand-Archive -Path '%TEMP%\\gdrcd.zip' -DestinationPath '%TEMP%\\gdrcd_temp' -Force}"
            echo     powershell -Command "& {$tempDir = Get-ChildItem -Path '%TEMP%\gdrcd_temp' -Directory | Select-Object -First 1; Copy-Item -Path (Join-Path $tempDir.FullName '*') -Destination '%WebFolder%' -Recurse -Force}"
            echo     del "%TEMP%\\gdrcd.zip" ^>nul 2^>^&1
            echo     rd /s /q "%TEMP%\\gdrcd_temp" ^>nul 2^>^&1
            echo     echo.
            call :SubPrintHeader "GDRCD installato ^con successo!" "SUCCESSS"
            echo     echo SUCCESS ^> "%GdrcdDownloadLog%"
            echo     timeout /t 3 /nobreak ^>nul
            echo ^) else ^(
            echo     echo.
            call :SubPrintHeader "ERRORE durante il download di GDRCD" "ERROR"
            echo     echo FAILED ^> "%GdrcdDownloadLog%"
            echo     echo.
            echo     echo Premi un tasto per chiudere questa finestra...
            echo     pause ^>nul
            echo ^)
        ) > "%TempGdrcdScript%"

        :: Eseguo lo script in una nuova finestra e attendo
        start "Download GDRCD" /wait cmd /c "%TempGdrcdScript%"

        :: Verifico il risultato
        if exist "%GdrcdDownloadLog%" (
            findstr /C:"SUCCESS" "%GdrcdDownloadLog%" >nul 2>&1
            if !ERRORLEVEL! EQU 0 (
                del "%GdrcdDownloadLog%" >nul 2>&1
                del "%TempGdrcdScript%" >nul 2>&1
                call :PrintHeader "GDRCD installato ^con successo!" "SUCCESSS"
                echo. 
                exit /B 0
            )
        )

        echo.
        call :PrintHeader "ERRORE: Download/Installazione GDRCD fallita!" "ERROR"
        del "%GdrcdDownloadLog%" >nul 2>&1
        del "%TempGdrcdScript%" >nul 2>&1
        pause
        goto Exit

    :: Apre un prompt per chiedere all'utente conferma per una data operazione
    :: Se l'esito è negativo lo script viene terminato
    :AskForUserConfirmation
        :: %~1 [in] - Custom question
        set QuestionText=%~1

        if "%QuestionText%"=="" (
            set /P UserAnswer="Confermi di voler proseguire? (Y/N) "
        ) else (
            set /P UserAnswer="%QuestionText% (Y/N) "
        )

        :: converto la scelta utente in uppercase
        set UserAnswer=%UserAnswer:~0,1%

        if /i "%UserAnswer%" neq "Y" (
            goto Exit
        )
        exit /B 0  

    :: Stampa un'intestazione formattata
    :PrintHeader
        :: %~1 [in] - Testo da visualizzare
        :: %~2 [in] - Tipo (SUCCESS, ERROR, WARNING, INFO, o vuoto per default)
        
        set "HeaderText=%~1"
        set "HeaderType=%~2"
        
        call :PrintHeaderLine
        
        if /i "!HeaderType!"=="SUCCESS" (
            echo [SUCCESSO] !HeaderText!
        ) else if /i "!HeaderType!"=="ERROR" (
            echo [ERRORE] !HeaderText! 
        ) else if /i "!HeaderType!"=="WARNING" (
            echo [ATTENZIONE] !HeaderText! 
        ) else if /i "!HeaderType!"=="INFO" (
            echo [INFO] !HeaderText!
        ) else (
            echo !HeaderText!
        )
        
        call :PrintHeaderLine
        
        exit /B 0

    :: Stampa una riga separatrice di intestazione
    :PrintHeaderLine
        echo ================================================================================        
        exit /B 0
        
    :: Stampa un'intestazione formattata per sottoroutine
    :SubPrintHeader
        :: %~1 [in] - Testo da visualizzare
        :: %~2 [in] - Tipo (SUCCESS, ERROR, WARNING, INFO, o vuoto per default)
        
        set "HeaderText=%~1"
        set "HeaderType=%~2"
        
        call :SubPrintHeaderLine
        
        if /i "!HeaderType!"=="SUCCESS" (
            echo echo [SUCCESSO] !HeaderText!
        ) else if /i "!HeaderType!"=="ERROR" (
            echo echo [ERRORE] !HeaderText! 
        ) else if /i "!HeaderType!"=="WARNING" (
            echo echo [ATTENZIONE] !HeaderText! 
        ) else if /i "!HeaderType!"=="INFO" (
            echo echo [INFO] !HeaderText!
        ) else (
            echo echo !HeaderText!
        )
        
        call :SubPrintHeaderLine
        
        exit /B 0
    
    :: Stampa una riga separatrice di intestazione per sottoroutine
    :SubPrintHeaderLine
        echo echo ================================================================================        
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

    :Exit
        echo.
        pause
        exit

:::: Fine ::::
