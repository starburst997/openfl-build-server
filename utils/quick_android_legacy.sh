#!/bin/bash
cd "$(dirname "$0")"
git pull
git submodule update --init --recursive
haxelib run openfl build ../project.android.xml android -verbose -Dgit=::GIT:: -Dversion=::VERSION:: -Dlegacy -Drelease
adb install ::APK::
adb shell am start -n ::PKG::/.MainActivity