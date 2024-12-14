#!/bin/bash

set -e

# Print a message ($2) in a visible way using a specified color ($1).
# (https://stackoverflow.com/questions/5947742/how-to-change-the-output-color-of-echo-in-linux)
LOG_MESSAGE() {
  echo -e "\n- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
  echo -e "\n \033[${1}m$2 \033[0m\n"
  echo -e "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -\n"
}

# Create an array with packages.
PACKAGE_PATHS=$(ls -d */)

# Base path of the repository.
BASE_PATH=$(echo "$PWD")

# Go through each updated package and tag it.
while IFS= read -r PACKAGE_PATH; do
  # Navigate to the package directory.
  cd $BASE_PATH/$PACKAGE_PATH

  LOG_MESSAGE "0" "[ℹ️] Running tests inside \`$BASE_PATH/$PACKAGE_PATH\`..."

  # Check if `pubspec.yaml` file exists.
  if [ ! -f "pubspec.yaml" ]; then
    LOG_MESSAGE "0" "[⏭️ ] \`pubspec.yaml\` file not found at \`$PACKAGE_PATH\`."
    continue
  fi

  # Optionally enable `custom_lint` package.
  if [ "$CUSTOM_LINT_ENABLED" = "true" ]; then
    LOG_MESSAGE "0" "[ℹ️] Enabling \`custom_lint\` package inside \`$PACKAGE_PATH\`..."
    dart pub add custom_lint --dev
    yq -i '.analyzer.plugins = ["custom_lint"]' analysis_options.yaml
  fi

  # Flutter-specific tests.
  if [ -n "$(yq -e '.dependencies.flutter // ""' pubspec.yaml)" ]; then
    LOG_MESSAGE "0" "[ℹ️] Running Flutter tests inside \`$PACKAGE_PATH\`..."

    # Format code.
    dart format . --set-exit-if-changed

    # Analyze code.
    flutter analyze

    # Check if `test` directory exists, then run tests.
    if [ -d "test" ]; then
      flutter test
    else
      echo "[⏭️] \`test\` directory doesn't exist - skipping."
    fi

    # Run custom lints.
    if [ "$CUSTOM_LINT_ENABLED" = "true" ]; then
      flutter pub run custom_lint
    fi
  else
    LOG_MESSAGE "0" "[ℹ️] Running Dart tests inside \`$PACKAGE_PATH\`..."

    # Format code.
    dart format . --set-exit-if-changed

    # Analyze code.
    dart analyze

    # Check if `test` directory exists, then run tests.
    if [ -d "test" ]; then
      dart test
    else
      echo "[⏭️] \`test\` directory doesn't exist - skipping."
    fi

    # Run custom lints.
    if [ "$CUSTOM_LINT_ENABLED" = "true" ]; then
      dart run custom_lint
    fi
  fi
done <<<"$PACKAGE_PATHS"

LOG_MESSAGE "32" "[✅] Finished at $(date -u +"%Y-%m-%d %H:%M:%S")"
