# openfl-build-server
My attempt to automate the build process of my openfl projects (actually could be adapted to any project)

The idea being that you have 3 VMs (I'm using Virtual Box): Windows (7), Linux (Ubuntu), Mac (Sierra). On a single machine (I'm using Windows 10), connected to the internet and open 24 / 7.

This repo does not include the files or instructions to setup the VMs, you need to install haxe / openfl and makes sure you can

    haxelib run openfl build XXXX

on your projects, also install 'git' and setup your ssh key, once this is done then you can install the startup script.

The startup script that run check if the git repositories have changes, if yes, then it 'git pull' on the folder and run the build script (Windows: windows / android, Mac: mac / ios, Linux: linux). Once the build is done, it saves the output to a log files and upload the files via sFTP to a server. An email is sent with the log and a link to the build.

I also want to automate the process as much as possible to send build to Google Play / Testflight / etc...

Very WIP and custom for my projects right now but I want to make it customizable.

Generate keystore like this

    keytool -genkey -v -keystore my-release-key.keystore -alias alias_name -keyalg RSA -keysize 2048 -validity 10000
