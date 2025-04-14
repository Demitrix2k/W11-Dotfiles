:loop
tasklist | find /i "yasb.exe" > nul
if errorlevel 1 (
    start "" "C:\Program Files\Yasb\yasb.exe"
)
timeout /t 60 /nobreak > nul
goto loop