taskkill /f /im whkd.exe
taskkill /f /im komorebic.exe
taskkill /f /im komorebi.exe
taskkill /f /im komorebi-bar.exe

komorebic start --whkd
# komorebic start --bar --whkd

echo Komorebic Running
timeout /t 30