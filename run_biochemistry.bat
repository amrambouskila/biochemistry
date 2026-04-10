@echo off
setlocal enabledelayedexpansion

set SERVICE_PREFIX=biochemistry
set COMPOSE_FILE=docker-compose.yml

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
echo   Building and starting containers...
echo.

docker compose -f %COMPOSE_FILE% up --build -d

if errorlevel 1 (
    echo   Error: Failed to start containers.
    pause
    exit /b 1
)

echo.
echo ============================================
echo   Services are running!
echo.
echo   Frontend:  http://localhost:5175
echo   Backend:   http://localhost:8000
echo   API Docs:  http://localhost:8000/docs
echo ============================================
echo.
echo   Shutdown options:
echo     [k] Stop containers (keep images)
echo     [q] Stop containers + remove images
echo     [v] Stop containers + remove images + remove volumes (full cleanup)
echo.

set /p choice="  Enter option when ready to stop: "

if /i "%choice%"=="k" goto :stop_keep
if /i "%choice%"=="q" goto :stop_remove
if /i "%choice%"=="v" goto :stop_full
goto :stop_keep

:stop_keep
echo.
echo   Stopping containers...
docker compose -f %COMPOSE_FILE% down
echo   Containers stopped. Images retained.
goto :done

:stop_remove
echo.
echo   Stopping containers and removing images...
docker compose -f %COMPOSE_FILE% down --remove-orphans
for /f "tokens=*" %%i in ('docker images --format "{{.Repository}}:{{.Tag}} {{.ID}}" ^| findstr "%SERVICE_PREFIX%"') do (
    for /f "tokens=2" %%j in ("%%i") do (
        docker rmi %%j 2>nul
    )
)
echo   Containers stopped. Images removed.
goto :done

:stop_full
echo.
echo   Stopping containers, removing images and volumes...
docker compose -f %COMPOSE_FILE% down --volumes --remove-orphans
for /f "tokens=*" %%i in ('docker images --format "{{.Repository}}:{{.Tag}} {{.ID}}" ^| findstr "%SERVICE_PREFIX%"') do (
    for /f "tokens=2" %%j in ("%%i") do (
        docker rmi %%j 2>nul
    )
)
echo   Full cleanup complete.
goto :done

:done
echo.
echo   Done.
pause
