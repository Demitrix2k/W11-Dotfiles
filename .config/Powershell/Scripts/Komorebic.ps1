taskkill /f /im whkd.exe
taskkill /f /im komorebic.exe
taskkill /f /im komorebi.exe

komorebic start --whkd
komorebic mouse-follows-focus disable

echo Komorebic Running
timeout /t 30