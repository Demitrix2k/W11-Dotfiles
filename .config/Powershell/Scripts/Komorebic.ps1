taskkill /f /im whkd.exe
taskkill /f /im komorebic.exe
taskkill /f /im komorebi.exe
taskkill /f /im komorebi-bar.exe

komorebic start --whkd
komorebic toggle-mouse-follows-focus
# komorebic start --bar --whkd
#  "mouse_follows_focus": false,
echo Komorebic Running
timeout /t 30