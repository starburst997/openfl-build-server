#!/bin/bash
cd "$(dirname "$0")"
fastlane supply --apk ::APK:: --track beta --package_name ::PKG:: --json_key ::JSON::