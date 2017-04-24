#!/bin/bash
cd "$(dirname "$0")"
adb install ::APK::
adb shell am start -n ::PACKAGE::/.MainActivity