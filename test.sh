#!/usr/bin/env sh

cd build/
sudo dpkg -i msys2-base-i686-20150512-20150731.deb
msys2init
msys2run "echo hello"
