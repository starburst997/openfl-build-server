#!/bin/bash
cd "$(dirname "$0")"
git pull origin master
git submodule update --init --recursive
haxelib run openfl build ../project.android.xml android -verbose -Dgit=::GIT:: -Dversion=::VERSION:: -final
adb install ::APK::
adb shell am start -n ::PKG::/.MainActivity