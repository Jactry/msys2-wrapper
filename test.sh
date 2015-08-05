#!/usr/bin/env sh

cd build/
sudo dpkg -i msys2-base-i686-20150512-20150805.deb
msys2init
msys2run "echo hello"
