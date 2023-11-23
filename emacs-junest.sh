#!/bin/sh

# NAME OF THE APP BY REPLACING "SAMPLE"
APP=emacs
BIN="$APP" #CHANGE THIS IF THE NAME OF THE BINARY IS DIFFERENT FROM "$APP" (for example, the binary of "obs-studio" is "obs")
DEPENDENCES="emacs-apel emacs-muse emacs-php-mode emacs-python-mode emacs-slime"
#BASICSTUFF="binutils gzip"
#COMPILERS="gcc"

# ADD A VERSION, THIS IS NEEDED FOR THE NAME OF THE FINEL APPIMAGE, IF NOT AVAILABLE ON THE REPO, THE VALUE COME FROM AUR, AND VICE VERSA
for REPO in { "core" "extra" "community" "multilib" }; do
echo "$(wget -q https://archlinux.org/packages/$REPO/x86_64/$APP/flag/ -O - | grep $APP | grep details | head -1 | grep -o -P '(?<=/a> ).*(?= )' | grep -o '^\S*')" >> version
done
VERSION=$(cat ./version | grep -w -v "" | head -1)
VERSIONAUR=$(wget -q https://aur.archlinux.org/cgit/aur.git/plain/PKGBUILD?h=$APP -O - | grep pkgver | head -1 | cut -c 8-)

# CREATE THE APPDIR (DON'T TOUCH THIS)...
wget -q https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage -O appimagetool
chmod a+x appimagetool
mkdir $APP.AppDir

# ENTER THE APPDIR
cd $APP.AppDir

# SET APPDIR AS A TEMPORARY $HOME DIRECTORY, THIS WILL DO ALL WORK INTO THE APPDIR
HOME="$(dirname "$(readlink -f $0)")" 

# DOWNLOAD AND INSTALL JUNEST (DON'T TOUCH THIS)
git clone https://github.com/fsquillace/junest.git ~/.local/share/junest
./.local/share/junest/bin/junest setup

# ENABLE MULTILIB (optional)
echo "
[multilib]
Include = /etc/pacman.d/mirrorlist" >> ./.junest/etc/pacman.conf

# ENABLE CHAOTIC-AUR
./.local/share/junest/bin/junest -- sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
./.local/share/junest/bin/junest -- sudo pacman-key --lsign-key 3056513887B78AEB
./.local/share/junest/bin/junest -- sudo pacman --noconfirm -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'
echo "
[chaotic-aur]
Include = /etc/pacman.d/chaotic-mirrorlist" >> ./.junest/etc/pacman.conf

# CUSTOM MIRRORLIST, THIS SHOULD SPEEDUP THE INSTALLATION OF THE PACKAGES IN PACMAN (COMMENT EVERYTHING TO USE THE DEFAULT MIRROR)
COUNTRY=$(curl -i ipinfo.io | grep country | cut -c 15- | cut -c -2)
rm -R ./.junest/etc/pacman.d/mirrorlist
wget -q https://archlinux.org/mirrorlist/?country="$(echo $COUNTRY)" -O - | sed 's/#Server/Server/g' >> ./.junest/etc/pacman.d/mirrorlist

# UPDATE ARCH LINUX IN JUNEST
./.local/share/junest/bin/junest -- sudo pacman -Syy
./.local/share/junest/bin/junest -- sudo pacman --noconfirm -Syu

# INSTALL THE PROGRAM USING YAY
./.local/share/junest/bin/junest -- yay -Syy
./.local/share/junest/bin/junest -- yay --noconfirm -S gnu-free-fonts $(echo "$BASICSTUFF $COMPILERS $DEPENDENCES $APP")

# SET THE LOCALE (DON'T TOUCH THIS)
#sed "s/# /#>/g" ./.junest/etc/locale.gen | sed "s/#//g" | sed "s/>/#/g" >> ./locale.gen # UNCOMMENT TO ENABLE ALL THE LANGUAGES
#sed "s/#$(echo $LANG)/$(echo $LANG)/g" ./.junest/etc/locale.gen >> ./locale.gen # ENABLE ONLY YOUR LANGUAGE, COMMENT IF YOU NEED MORE THAN ONE
#rm ./.junest/etc/locale.gen
#mv ./locale.gen ./.junest/etc/locale.gen
rm ./.junest/etc/locale.conf
#echo "LANG=$LANG" >> ./.junest/etc/locale.conf
sed -i 's/LANG=${LANG:-C}/LANG=$LANG/g' ./.junest/etc/profile.d/locale.sh
#./.local/share/junest/bin/junest -- sudo pacman --noconfirm -S glibc gzip
#./.local/share/junest/bin/junest -- sudo locale-gen

# ...ADD THE ICON AND THE DESKTOP FILE AT THE ROOT OF THE APPDIR...
rm -R -f ./*.desktop
cp -r ./.junest/usr/share/applications/$APP.desktop ./ 2>/dev/null
cp -r ./.junest/usr/share/icons/hicolor/scalable/apps/$APP.svg ./ 2>/dev/null

# ...AND FINALLY CREATE THE APPRUN, IE THE MAIN SCRIPT TO RUN THE APPIMAGE!
# EDIT THE FOLLOWING LINES IF YOU THINK SOME ENVIRONMENT VARIABLES ARE MISSING
rm -R -f ./AppRun
cat >> ./AppRun << 'EOF'
#!/bin/sh
HERE="$(dirname "$(readlink -f $0)")"
export UNION_PRELOAD=$HERE
export JUNEST_HOME=$HERE/.junest
export PATH=$HERE/.local/share/junest/bin/:$PATH
mkdir -p $HOME/.cache
EXEC=$(grep -e '^Exec=.*' "${HERE}"/*.desktop | head -n 1 | cut -d "=" -f 2- | sed -e 's|%.||g')
VER=$(ls $JUNEST_HOME/usr/bin/ | grep emacs | sort | head -3 | tail -1 | cut -c 6-)
export EMACSPATH=${JUNEST_HOME}/usr/share/emacs/$(ls ${JUNEST_HOME}/usr/share/emacs/ | sort | head -1)/
export EMACSDATA=$EMACSPATH/etc
export EMACSDOC=$EMACSPATH/etc
export EMACSLOADPATH=$EMACSPATH/site-lisp:$EMACSPATH/lisp:$EMACSPATH/lisp/emacs-lisp
$HERE/.local/share/junest/bin/junest proot -n -b "--bind=/home --bind=/home/$(echo $USER) --bind=/media --bind=/mnt --bind=/opt --bind=/usr/lib/locale --bind=/etc/fonts --bind=/usr/share/fonts --bind=/usr/share/themes"  2> /dev/null -- $EXEC "$@"
EOF
chmod a+x ./AppRun

# REMOVE "READ-ONLY FILE SYSTEM" ERRORS
sed -i 's#${JUNEST_HOME}/usr/bin/junest_wrapper#${HOME}/.cache/junest_wrapper.old#g' ./.local/share/junest/lib/core/wrappers.sh
sed -i 's/rm -f "${JUNEST_HOME}${bin_path}_wrappers/#rm -f "${JUNEST_HOME}${bin_path}_wrappers/g' ./.local/share/junest/lib/core/wrappers.sh
sed -i 's/ln/#ln/g' ./.local/share/junest/lib/core/wrappers.sh

# EXIT THE APPDIR
cd ..

# REMOVE SOME BLOATWARES
find ./$APP.AppDir/.junest/usr/share/doc/* -not -iname "*$BIN*" -a -not -name "." -delete #REMOVE ALL DOCUMENTATION NOT RELATED TO THE APP
find ./$APP.AppDir/.junest/usr/share/locale/*/*/* -not -iname "*$BIN*" -a -not -name "." -delete #REMOVE ALL ADDITIONAL LOCALE FILES
rm -R -f ./$APP.AppDir/.junest/etc/makepkg.conf
rm -R -f ./$APP.AppDir/.junest/etc/pacman.conf
rm -R -f ./$APP.AppDir/.junest/usr/include
rm -R -f ./$APP.AppDir/.junest/var/* #REMOVE ALL PACKAGES DOWNLOADED WITH THE PACKAGE MANAGER

# ADDITIONAL REMOVALS
mkdir save

cp -r ./$APP.AppDir/.junest/usr/bin/emacs* ./save/
cp -r ./$APP.AppDir/.junest/usr/bin/bash ./save/
cp -r ./$APP.AppDir/.junest/usr/bin/env ./save/
cp -r ./$APP.AppDir/.junest/usr/bin/proot* ./save/
cp -r ./$APP.AppDir/.junest/usr/bin/sh ./save/
rm -R -f ./$APP.AppDir/.junest/usr/bin/*
mv ./save/* ./$APP.AppDir/.junest/usr/bin/

rm -R -f ./$APP.AppDir/.junest/usr/lib/*.a
rm -R -f ./$APP.AppDir/.junest/usr/lib/*.o
cp -r ./$APP.AppDir/.junest/usr/lib/ld-linux-x86-64.so.* ./save/
cp -r ./$APP.AppDir/.junest/usr/lib/libacl.so* ./save/
cp -r ./$APP.AppDir/.junest/usr/lib/libasound.so* ./save/
cp -r ./$APP.AppDir/.junest/usr/lib/libatk-* ./save/
cp -r ./$APP.AppDir/.junest/usr/lib/libatspi.so* ./save/
cp -r ./$APP.AppDir/.junest/usr/lib/libblkid* ./save/
cp -r ./$APP.AppDir/.junest/usr/lib/libbrotlicommon.so* ./save/
cp -r ./$APP.AppDir/.junest/usr/lib/libbrotli* ./save/
cp -r ./$APP.AppDir/.junest/usr/lib/libbz2.so* ./save/
cp -r ./$APP.AppDir/.junest/usr/lib/libcairo* ./save/
cp -r ./$APP.AppDir/.junest/usr/lib/libcap* ./save/
cp -r ./$APP.AppDir/.junest/usr/lib/libcloudproviders.so* ./save/
cp -r ./$APP.AppDir/.junest/usr/lib/libcrypt* ./save/
cp -r ./$APP.AppDir/.junest/usr/lib/libc.so* ./save/
cp -r ./$APP.AppDir/.junest/usr/lib/libdatrie.so* ./save/
cp -r ./$APP.AppDir/.junest/usr/lib/libdbus-* ./save/
cp -r ./$APP.AppDir/.junest/usr/lib/libepoxy.so* ./save/
cp -r ./$APP.AppDir/.junest/usr/lib/libexpat.so* ./save/
cp -r ./$APP.AppDir/.junest/usr/lib/libffi.so* ./save/
cp -r ./$APP.AppDir/.junest/usr/lib/libfontconfig.so* ./save/
cp -r ./$APP.AppDir/.junest/usr/lib/libfreetype.so* ./save/
cp -r ./$APP.AppDir/.junest/usr/lib/libfribidi.so* ./save/
cp -r ./$APP.AppDir/.junest/usr/lib/libgcc_s.so* ./save/
cp -r ./$APP.AppDir/.junest/usr/lib/libgcrypt.so* ./save/
cp -r ./$APP.AppDir/.junest/usr/lib/libgdk-* ./save/
cp -r ./$APP.AppDir/.junest/usr/lib/libgdk_pixbuf-* ./save/
cp -r ./$APP.AppDir/.junest/usr/lib/libgif.so* ./save/
cp -r ./$APP.AppDir/.junest/usr/lib/libgio-* ./save/
cp -r ./$APP.AppDir/.junest/usr/lib/libglib-* ./save/
cp -r ./$APP.AppDir/.junest/usr/lib/libgmodule-* ./save/
cp -r ./$APP.AppDir/.junest/usr/lib/libgmp.so* ./save/
cp -r ./$APP.AppDir/.junest/usr/lib/libgmpxx.so* ./save/
cp -r ./$APP.AppDir/.junest/usr/lib/libgnutls* ./save/
cp -r ./$APP.AppDir/.junest/usr/lib/libgobject-* ./save/
cp -r ./$APP.AppDir/.junest/usr/lib/libgpg-error.so* ./save/
cp -r ./$APP.AppDir/.junest/usr/lib/libgpgme* ./save/
cp -r ./$APP.AppDir/.junest/usr/lib/libgpm.so* ./save/
cp -r ./$APP.AppDir/.junest/usr/lib/libgraphite* ./save/
cp -r ./$APP.AppDir/.junest/usr/lib/libgtk-* ./save/
cp -r ./$APP.AppDir/.junest/usr/lib/libharfbuzz* ./save/
cp -r ./$APP.AppDir/.junest/usr/lib/libhogweed.so* ./save/
cp -r ./$APP.AppDir/.junest/usr/lib/libICE.so* ./save/
cp -r ./$APP.AppDir/.junest/usr/lib/libicu* ./save/
cp -r ./$APP.AppDir/.junest/usr/lib/libidn* ./save/
cp -r ./$APP.AppDir/.junest/usr/lib/libjansson.so* ./save/
cp -r ./$APP.AppDir/.junest/usr/lib/libjbig* ./save/
cp -r ./$APP.AppDir/.junest/usr/lib/libjpeg.so* ./save/
cp -r ./$APP.AppDir/.junest/usr/lib/libjson-* ./save/
cp -r ./$APP.AppDir/.junest/usr/lib/liblcms* ./save/
cp -r ./$APP.AppDir/.junest/usr/lib/liblz* ./save/
cp -r ./$APP.AppDir/.junest/usr/lib/libm* ./save/
cp -r ./$APP.AppDir/.junest/usr/lib/libncursesw.so* ./save/
cp -r ./$APP.AppDir/.junest/usr/lib/libnettle.so* ./save/
cp -r ./$APP.AppDir/.junest/usr/lib/libotf.so* ./save/
cp -r ./$APP.AppDir/.junest/usr/lib/libp11-kit.so* ./save/
cp -r ./$APP.AppDir/.junest/usr/lib/libpango* ./save/
cp -r ./$APP.AppDir/.junest/usr/lib/libpcre* ./save/
cp -r ./$APP.AppDir/.junest/usr/lib/libpixman-* ./save/
cp -r ./$APP.AppDir/.junest/usr/lib/libpng* ./save/
cp -r ./$APP.AppDir/.junest/usr/lib/libreadline.so* ./save/
cp -r ./$APP.AppDir/.junest/usr/lib/librsvg-* ./save/
cp -r ./$APP.AppDir/.junest/usr/lib/libsharpyuv.so* ./save/
cp -r ./$APP.AppDir/.junest/usr/lib/libSM.so* ./save/
cp -r ./$APP.AppDir/.junest/usr/lib/libsqlite* ./save/
cp -r ./$APP.AppDir/.junest/usr/lib/libstdc++.so* ./save/
cp -r ./$APP.AppDir/.junest/usr/lib/libsystemd.so* ./save/
cp -r ./$APP.AppDir/.junest/usr/lib/libtasn* ./save/
cp -r ./$APP.AppDir/.junest/usr/lib/libthai.so* ./save/
cp -r ./$APP.AppDir/.junest/usr/lib/libtiff.so* ./save/
cp -r ./$APP.AppDir/.junest/usr/lib/libtracker-sparql-* ./save/
cp -r ./$APP.AppDir/.junest/usr/lib/libtree-sitter.so* ./save/
cp -r ./$APP.AppDir/.junest/usr/lib/libunistring.so* ./save/
cp -r ./$APP.AppDir/.junest/usr/lib/libuuid.so* ./save/
cp -r ./$APP.AppDir/.junest/usr/lib/libwayland-* ./save/
cp -r ./$APP.AppDir/.junest/usr/lib/libwebp* ./save/
cp -r ./$APP.AppDir/.junest/usr/lib/libX11* ./save/
cp -r ./$APP.AppDir/.junest/usr/lib/libXau.so* ./save/
cp -r ./$APP.AppDir/.junest/usr/lib/libxcb* ./save/
cp -r ./$APP.AppDir/.junest/usr/lib/libXcomposite.so* ./save/
cp -r ./$APP.AppDir/.junest/usr/lib/libXcursor.so* ./save/
cp -r ./$APP.AppDir/.junest/usr/lib/libXdamage.so* ./save/
cp -r ./$APP.AppDir/.junest/usr/lib/libXdmcp.so* ./save/
cp -r ./$APP.AppDir/.junest/usr/lib/libXext.so* ./save/
cp -r ./$APP.AppDir/.junest/usr/lib/libXfixes.so* ./save/
cp -r ./$APP.AppDir/.junest/usr/lib/libXinerama.so* ./save/
cp -r ./$APP.AppDir/.junest/usr/lib/libXi.so* ./save/
cp -r ./$APP.AppDir/.junest/usr/lib/libxkbcommon.so* ./save/
cp -r ./$APP.AppDir/.junest/usr/lib/libxkbregistry.so* ./save/
cp -r ./$APP.AppDir/.junest/usr/lib/libxml* ./save/
cp -r ./$APP.AppDir/.junest/usr/lib/libXrandr.so* ./save/
cp -r ./$APP.AppDir/.junest/usr/lib/libXrender.so* ./save/
cp -r ./$APP.AppDir/.junest/usr/lib/libz.so* ./save/
cp -r ./$APP.AppDir/.junest/usr/lib/libzstd.so* ./save/
rm -R -f ./$APP.AppDir/.junest/usr/lib/*
mv ./save/* ./$APP.AppDir/.junest/usr/lib/

cp -r ./$APP.AppDir/.junest/usr/share/emacs ./save/
cp -r ./$APP.AppDir/.junest/usr/share/fontconfig ./save/
cp -r ./$APP.AppDir/.junest/usr/share/glib-* ./save/
cp -r ./$APP.AppDir/.junest/usr/share/locale ./save/
cp -r ./$APP.AppDir/.junest/usr/share/mime ./save/
cp -r ./$APP.AppDir/.junest/usr/share/wayland ./save/
cp -r ./$APP.AppDir/.junest/usr/share/X11 ./save/
rm -R -f ./$APP.AppDir/.junest/usr/share/*
mv ./save/* ./$APP.AppDir/.junest/usr/share/

rmdir save

# REMOVE THE INBUILT HOME
rm -R -f ./$APP.AppDir/.junest/home

# ENABLE MOUNTPOINTS
mkdir -p ./$APP.AppDir/.junest/home
mkdir -p ./$APP.AppDir/.junest/media

# CREATE THE APPIMAGE
ARCH=x86_64 ./appimagetool -n ./$APP.AppDir
mv ./*AppImage ./"$(cat ./$APP.AppDir/*.desktop | grep 'Name=' | head -1 | cut -c 6- | sed 's/ /-/g')"_"$VERSION""$VERSIONAUR"-ivan-hc-review20231123-x86_64.AppImage
