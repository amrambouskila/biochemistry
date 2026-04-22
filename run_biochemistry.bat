@echo off
setlocal enabledelayedexpansion

set "SERVICE_PREFIX=biochemistry"
set "COMPOSE_FILE=docker-compose.yml"
set "DEV_OVERLAY=docker-compose.dev.yml"
set "COMPOSE_ARGS=-f %COMPOSE_FILE% -f %DEV_OVERLAY%"

call :print_banner
call :start_services
if errorlevel 1 (
    echo   Error: Failed to start containers.
    pause
    exit /b 1
)
call :show_menu

:main_loop
set "choice="
set /p "choice=  Enter option: "
if /I "%choice%"=="r" goto do_restart
if /I "%choice%"=="k" goto do_stop_keep
if /I "%choice%"=="q" goto do_stop_remove
if /I "%choice%"=="v" goto do_stop_full
echo   Unrecognized option '%choice%'. Valid options: [r] [k] [q] [v].
call :show_menu
goto main_loop

:do_restart
echo.
echo   Restarting...
docker compose %COMPOSE_ARGS% down
echo.
call :start_services
call :show_menu
goto main_loop

:do_stop_keep
echo.
echo   Stopping containers...
docker compose %COMPOSE_ARGS% down
echo   Containers stopped. Images retained.
goto end_script

:do_stop_remove
echo.
echo   Stopping containers and removing project images...
docker compose %COMPOSE_ARGS% down --remove-orphans
call :remove_project_images
echo   Containers stopped. Images removed. Volumes retained.
goto end_script

:do_stop_full
echo.
echo   Stopping containers, removing images and volumes...
docker compose %COMPOSE_ARGS% down --volumes --remove-orphans
call :remove_project_images
echo   Full cleanup complete.
goto end_script

REM ============================================================
REM   Helpers
REM ============================================================

:print_banner
echo ============================================
echo   Biochemistry — Starting Services
echo ============================================
echo.
echo   Services:
echo     - PostgreSQL  (port 5432)
echo     - Redis       (port 6379)
echo     - Backend     (port 8000)
echo     - Frontend    (port 5175)
echo.
goto :eof

:start_services
echo   Building and starting containers...
echo.
docker compose %COMPOSE_ARGS% up --build -d
if errorlevel 1 exit /b 1
echo.
echo ============================================
echo   Services are running!
echo.
echo   Frontend:  http://localhost:5175
echo   Backend:   http://localhost:8000
echo   API Docs:  http://localhost:8000/docs
echo ============================================
goto :eof

:show_menu
echo.
echo   Menu:
echo     [r] Restart (rebuild and relaunch)
echo     [k] Stop containers (keep images)
echo     [q] Stop containers + remove project images
echo     [v] Stop containers + remove images + remove volumes (full cleanup)
echo.
goto :eof

:remove_project_images
for /f "tokens=*" %%i in ('docker images --format "{{.Repository}}:{{.Tag}} {{.ID}}" ^| findstr "%SERVICE_PREFIX%"') do (
    for /f "tokens=2" %%j in ("%%i") do (
        docker rmi %%j 2>nul
    )
)
goto :eof

:end_script
echo.
echo   Done.
pause
exit /b 0
