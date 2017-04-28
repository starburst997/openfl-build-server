#!/bin/bash
cd "$(dirname "$0")"
git pull origin master
git submodule update --init --recursive
haxelib run openfl build ../project.ios.xml ios -verbose -Dgit=::GIT:: -Dversion=::VERSION:: -Dlegacy -Dsource-header=0
ios-deploy -r --justlaunch --bundle ::FILE::