@echo off

echo _
echo Makes sure you have GIT / NPM / ImageMagick installed
echo Have your ssh key saved in '~/.ssh/id_rsa'
echo _
@pause
echo _
echo Installing 'switchx'...
npm install haxeshim -g && npm install switchx -g && switchx
switchx install latest
echo _
echo Adding to haxelib...
haxelib dev openfl-build-server ..
echo _
echo Now add this command to the scheduler ("Log on")
echo if you want to have it started automatically
echo _
echo cmd /k "cd %0\.. & start-ssh-agent & run"
echo _
@pause
echo _
echo That's pretty much it, now all you need to do
echo is add your git projects to the 'projects' folder
echo _
echo git submodule add git@github.com:starburst997/openfl-sample-1.git
echo _
echo Start the script run.sh using `git bash` (windows cmd doesn't seem to works well...)
echo _
echo Install NSIS
echo _
@pause