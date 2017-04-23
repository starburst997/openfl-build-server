#!/bin/bash
cd "$(dirname "$0")"
echo .
echo Makes sure your sessions is up to date with this command!
echo .
echo fastlane spaceauth -u failsafegames@gmail.com
echo .
fastlane deliver -u failsafegames@gmail.com --ipa ::FILE:: --force