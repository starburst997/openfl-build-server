@echo off
REM Add this "Log on" task to Scheduler
REM cmd /k "cd C:\Users\starburst\projects\openfl-build-server & start-ssh-agent & run"
haxelib dev openfl-build-server .
haxelib run openfl-build-server .