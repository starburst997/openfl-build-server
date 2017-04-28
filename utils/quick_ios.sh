#!/bin/bash
cd "$(dirname "$0")"
git pull
git submodule update --init --recursive
haxelib run openfl build ../project.xml ios -verbose -Dgit=::GIT:: -Dversion=::VERSION:: -final
ios-deploy -r --justlaunch --bundle ::FILE::