# DemitriX's Windows 11 Dotfiles

![Screenshot 2024-11-24 082550](https://github.com/user-attachments/assets/24e1b45e-d121-48b2-a1cf-e53f83fec5cf)

<details>
  
#### Custom W11 theme, Yazi file terminal explorer
  
![Screenshot 2024-11-24 083158](https://github.com/user-attachments/assets/41ebd397-e39a-4b7b-a882-8db4f7024a39)

#### Firefox + Discord custom  
![Screenshot 2024-11-24 082340](https://github.com/user-attachments/assets/8477f176-866e-4160-a22f-662485e1a0f4)

  <summary>Additional Screenshots</summary>
  
</details>


# Configuration files for
-  [FastFetch](https://github.com/fastfetch-cli/fastfetch)
-  [Firefox](https://www.mozilla.org/en-US/firefox/new/)
-  [Komorebi](https://github.com/LGUG2Z/komorebi)
-  [Ntop](https://github.com/gsass1/NTop)
-  [whkd](https://github.com/LGUG2Z/whkd)
-  [yasb](github.com/amnweb/yasb)
-  [yazi](https://github.com/sxyazi/yazi)

 # Windows configurations
 -  [SecureUxTheme](https://github.com/namazso/SecureUxTheme) to use custom themes.
 -  [Nu-Xi - Dark](https://www.deviantart.com/niivu/art/NUXI-for-Windows-11-950599065) W11 theme by **niivu**.  
 -  [Windhawk](https://windhawk.net/) For configuring Taskbar and start menu.
 -  - Portable install launch on startup with `-tray-only` parameter.
 -  [AltSnap](https://github.com/RamonUnch/AltSnap) - move and resize window selecting it with alt + mouseclick. 
 - - portable install
 - [ExplorerPatcher](https://github.com/valinet/ExplorerPatcher) Disable rounded corners, improved alt tab, and more.
 - [Flow Launcher](https://github.com/Flow-Launcher/Flow.Launcher) Better search and app launcher.

# Additional tidbits
- [Betterfox](https://github.com/yokoffing/Betterfox)
- [Vencord](https://vencord.dev/)


# Installation



1. Clone repo
```pwsh
# Using gh
gh repo clone Demitrix2k/W11-Dotfiles $HOME\

# ...or use HTTPS and switch remotes later.
git clone https://github.com/Demitrix2k/W11-Dotfiles.git $HOME\

#....or download zip manually and place within $HOME\
```

2. Run Powershell as admin or use sudo and link these files and folders
```pwsh
New-Item -ItemType SymbolicLink -Target $HOME\.config\Powershell -Path $HOME\Documents\Powershell

New-Item -ItemType SymbolicLink -Target $HOME\.config\Firefox -Path $Env:appdata\Mozilla\Firefox\Profiles\PROFILENAMEHERE\chrome

New-Item -ItemType SymbolicLink -Target $HOME\.config\ntop\ntop.conf -Path $Env:LocalAppdata\Microsoft\WinGet\Packages\gsass1.NTop_Microsoft.Winget.Source_8wekyb3d8bbwe\ntop.conf
```
3. 
