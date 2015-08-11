#!/usr/bin/env sh

. src/msys2env

set -e

SOURCE_PATH=`pwd`
BUILD_ETC=build/deb/etc/
if ! test -d ${BUILD_ETC}
then
    mkdir -p ${BUILD_ETC}
fi
cp src/msys2env ${BUILD_ETC}

BUILD_USR=build/deb/usr/bin/
if ! test -d ${BUILD_USR}
then
    mkdir -p ${BUILD_USR}
fi
cp src/*run ${BUILD_USR}
cp src/msys2init ${BUILD_USR}
chmod +x ${BUILD_USR}/*

DISPLAY=:88.0 WINEDEBUG=-all wineboot # hack - wineboot without display, create wineprefix in a quick way, workaround Travis CI timeout (FIXME)

MSYS2_CACHE=build/installer
if ! test -d ${MSYS2_CACHE}
then
    mkdir -p ${MSYS2_CACHE}
fi

MSYS2_INSTALLER=msys2-base-i686-20150512
if ! test -f ${MSYS2_CACHE}/${MSYS2_INSTALLER}.tar.xz
then
    cd ${MSYS2_CACHE}
    wget http://sourceforge.net/projects/msys2/files/Base/i686/${MSYS2_INSTALLER}.tar.xz
fi

cd $WINEPREFIX/drive_c
if test -d "msys32"
then
    echo "msys32 alrealy existed."
    exit 1
fi
tar xf ${SOURCE_PATH}/${MSYS2_CACHE}/${MSYS2_INSTALLER}.tar.xz

# Set new msys2 mirror
echo "Server = http://45.59.69.178/msys/\$arch" > ${MSYS_ROOT}/etc/pacman.d/mirrorlist.msys
echo "Server = http://45.59.69.178/mingw/i686" > ${MSYS_ROOT}/etc/pacman.d/mirrorlist.mingw32
echo "Server = http://45.59.69.178/mingw/x86_64" > ${MSYS_ROOT}/etc/pacman.d/mirrorlist.mingw64

cd ${SOURCE_PATH}/${BUILD_USR}

./msys2run "echo restart"
./msys2run "pacman -Sy"
./msys2run "pacman -Sy"
./msys2run "pacman -S --needed --noconfirm msys2-runtime pacman pacman-mirrors"
./msys2run "pacman -S --needed --noconfirm msys2-runtime pacman pacman-mirrors"

# Set new msys2 mirror
echo "Server = http://45.59.69.178/msys/\$arch" > ${MSYS_ROOT}/etc/pacman.d/mirrorlist.msys
echo "Server = http://45.59.69.178/mingw/i686" > ${MSYS_ROOT}/etc/pacman.d/mirrorlist.mingw32
echo "Server = http://45.59.69.178/mingw/x86_64" > ${MSYS_ROOT}/etc/pacman.d/mirrorlist.mingw64

./msys2run "pacman -Sy"
./msys2run "pacman -Sy"
./msys2run "pacman -Su --noconfirm"
./msys2run "pacman -Su --noconfirm"
./msys2run "pacman -S --needed --noconfirm msys2-devel"
./msys2run "pacman -S --needed --noconfirm msys2-devel"
./msys2run "pacman -S --needed --noconfirm base-devel"
./msys2run "pacman -S --needed --noconfirm base-devel"
./msys2run "pacman -S --needed --noconfirm git"
./msys2run "pacman -S --needed --noconfirm git"
./msys2run "pacman -S --needed --noconfirm wget"
./msys2run "pacman -S --needed --noconfirm wget"
./msys2run "pacman -S --needed --noconfirm mingw-w64-i686-toolchain"
./msys2run "pacman -S --needed --noconfirm mingw-w64-i686-toolchain"

# replace xz -T0 by xz -T1, workaround wine-staging bug 241 - https://bugs.wine-staging.com/show_bug.cgi?id=241
./msys2run "pacman -S --needed --noconfirm mingw-w64-i686-xz"
./msys2run "pacman -S --needed --noconfirm mingw-w64-i686-xz"
echo replace msys2 xz by mingw32 xz, workaround wine-staging bug 241
sed -i 's/xz -c -z -T0 -/xz -c -z -T1 -/' ${MSYS_ROOT}/etc/makepkg.conf
sed -i 's/xz -c -z -T0 -/xz -c -z -T1 -/' ${MSYS_ROOT}/etc/makepkg_mingw32.conf
sed -i 's/xz -c -z -T0 -/xz -c -z -T1 -/' ${MSYS_ROOT}/etc/makepkg_mingw64.conf

# replace msys2 xz by mingw32 xz, workaround wine-staging bug 394 - https://bugs.wine-staging.com/show_bug.cgi?id=394
echo replace msys2 xz by mingw32 xz, workaround wine-staging bug 394
sed -i 's/xz -d -c/\/mingw32\/bin\/xz -d -c/' ${MSYS_ROOT}/usr/bin/autopoint

# disable autom4te flock, workaround wine staging bug 466 in travis ci old kernel - https://bugs.wine-staging.com/show_bug.cgi?id=466
sed -i "s/flock_implemented = 'yes'/flock_implemented = 'no'/" ${MSYS_ROOT}/usr/bin/autom4te

# replace mingw32 msgfmt by msys msgfmt
mv ${MSYS_ROOT}/mingw32/bin/msgfmt.exe ${MSYS_ROOT}/mingw32/bin/msgfmt.exe_back
ln -s ${MSYS_ROOT}/usr/bin/msgfmt.exe ${MSYS_ROOT}/mingw32/bin/msgfmt.exe

# replace mingw32 msgfmt by msys msgmerge
mv ${MSYS_ROOT}/mingw32/bin/msgmerge.exe ${MSYS_ROOT}/mingw32/bin/msgmerge.exe_back
ln -s ${MSYS_ROOT}/usr/bin/msgmerge.exe ${MSYS_ROOT}/mingw32/bin/msgmerge.exe

# clean pacman cache
rm -rf ${MSYS_ROOT}/var/cache/pacman/pkg/*

cd $WINEPREFIX/drive_c
NEW_MSYS2_PACKAGE=${MSYS2_INSTALLER}-20150805
tar zcf ${NEW_MSYS2_PACKAGE}.tar.gz msys32
if ! test -d ${SOURCE_PATH}/build/deb/opt/msys2/
then
    mkdir -p ${SOURCE_PATH}/build/deb/opt/msys2
fi
cp ${NEW_MSYS2_PACKAGE}.tar.gz ${SOURCE_PATH}/build/deb/opt/msys2

echo "shasum:"
sha1sum ${NEW_MSYS2_PACKAGE}.tar.gz

cd ${SOURCE_PATH}/build/
dpkg -b deb ${NEW_MSYS2_PACKAGE}.deb
pwd

echo "shasum:"
sha1sum ${NEW_MSYS2_PACKAGE}.deb
ls
mkdir upload_dir
mv ${SOURCE_PATH}/build/${NEW_MSYS2_PACKAGE}.deb upload_dir
