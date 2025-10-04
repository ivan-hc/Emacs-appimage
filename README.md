This repository provides Unofficial AppImages of Emacs built on top of [JuNest](https://github.com/fsquillace/junest) and the scripts to built them.

You can download the last continuous version from [here](https://github.com/ivan-hc/Emacs-appimage/releases/tag/continuous).

Previously, this Appimage was based on the official PPA, but given the gradual abandonment of .deb packages in favor of Snaps, the latest version available is 28_28.1.1. You can download it from [here](https://github.com/ivan-hc/Emacs-appimage/releases/tag/28.1.1) if you have any problems with JuNest based versions, with "AM" and AppMan (keep reading) you can also downgrade via the `--rollback` option.

###### NOTE: *This repository is inspired by [github.com/probonopd/Emacs.AppImage](https://github.com/probonopd/Emacs.AppImage) and created to make sure that "AM" and AppMan users don't get left behind!*

-------------------------
### Reduce the size of the JuNest based Appimage
You can analyze the presence of excess files inside the AppImage by extracting it:

    ./*.AppImage --appimage-extract
To start your tests, run the "AppRun" script inside the "squashfs-root" folder extracted from the AppImage:

    ./squashfs-root/AppRun

------------------------------------------------------------------------

## Install and update it with ease

### *"*AM*" Application Manager* 
#### *Package manager, database & solutions for all AppImages and portable apps for GNU/Linux!*

[![sample.png](https://raw.githubusercontent.com/ivan-hc/AM/main/sample/sample.png)](https://github.com/ivan-hc/AM)

[![Readme](https://img.shields.io/github/stars/ivan-hc/AM?label=%E2%AD%90&style=for-the-badge)](https://github.com/ivan-hc/AM/stargazers) [![Readme](https://img.shields.io/github/license/ivan-hc/AM?label=&style=for-the-badge)](https://github.com/ivan-hc/AM/blob/main/LICENSE)

*"AM"/"AppMan" is a set of scripts and modules for installing, updating, and managing AppImage packages and other portable formats, in the same way that APT manages DEBs packages, DNF the RPMs, and so on... using a large database of Shell scripts inspired by the Arch User Repository, each dedicated to an app or set of applications.*

*The engine of "AM"/"AppMan" is the "APP-MANAGER" script which, depending on how you install or rename it, allows you to install apps system-wide (for a single system administrator) or locally (for each user).*

*"AM"/"AppMan" aims to be the default package manager for all AppImage packages, giving them a home to stay.*

*You can consult the entire **list of managed apps** at [**portable-linux-apps.github.io/apps**](https://portable-linux-apps.github.io/apps).*

## *Go to *https://github.com/ivan-hc/AM* for more!*

------------------------------------------------------------------------

| [***Install "AM"***](https://github.com/ivan-hc/AM) | [***See all available apps***](https://portable-linux-apps.github.io) | [***Support me on ko-fi.com***](https://ko-fi.com/IvanAlexHC) | [***Support me on PayPal.me***](https://paypal.me/IvanAlexHC) |
| - | - | - | - |

------------------------------------------------------------------------
