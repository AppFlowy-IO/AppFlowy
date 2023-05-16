#!/bin/bash

if [ "$RUNNER_OS" == "Linux" ]; then
  export DISPLAY=:99
  sudo Xvfb -ac :99 -screen 0 1280x1024x24 > /dev/null 2>&1 &
  sudo apt-get install network-manager
  flutter test integration_test/runner.dart -d Linux --coverage --verbose
elif [ "$RUNNER_OS" == "macOS" ]; then
  flutter test integration_test/runner.dart -d macOS --coverage --verbose
elif [ "$RUNNER_OS" == "Windows" ]; then
  flutter test integration_test/runner.dart -d Windows --coverage --verbose
fi
