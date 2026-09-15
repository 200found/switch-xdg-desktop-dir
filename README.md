# switch-xdg-desktop-dir
a shell script to switch your xdg desktop dir folder.

changes the xdg desktop under kde 6 plasma to another, existing folder. supports a cyclable history and can be used with a virtual desktop switch or a right-click service.

## dependencies: 
- freedesktop
- bash 4
- mapfile
- kdialog (kde) or notify-send (linux mint xfce)

## todo
- support more window managers. i started this while using linux mint xfce and now much prefer kde.
- more robust checks for history and input
- make installer and adjacent scripts for more platforms
- make documetation and language more consistent
- localize

## notes
it's been like 20 years since i last did any serious programming, so there's a lot of good practices i didn't know of when i wrote this. compsci is no longer my career. if you would like to help modernize this, i would welcome input on the matter.

### kde directories for right-click services
- ~/.local/share/kio/servicemenus/
- ~/.local/share/applications/
