#!/bin/bash

set -e

# Print a message ($2) in a visible way using a specified color ($1).
# (https://stackoverflow.com/questions/5947742/how-to-change-the-output-color-of-echo-in-linux)
LOG_MESSAGE() {
  echo -e "\n- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
  echo -e "\n \033[${1}m$2 \033[0m\n"
  echo -e "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -\n"
}

# Create an array with packages based on CHANGELOG.md files.
PACKAGE_PATHS=$(git diff --name-only HEAD^ -- | grep "/CHANGELOG.md" | sed 's/\/CHANGELOG.md//g')

# Base path of the repository.
BASE_PATH=$(echo "$PWD")

# Go through each updated package and tag it.
while IFS= read -r PACKAGE_PATH; do
  # Navigate to the package directory.
  cd $BASE_PATH/$PACKAGE_PATH

  # Check if `pubspec.yaml` file exists.
  if [ ! -f "pubspec.yaml" ]; then
    LOG_MESSAGE "0" "[⏭️] \`pubspec.yaml\` file not found at \`$PACKAGE_PATH\`."
    continue
  fi

  # Check if `pubspec.yaml` is publishable (doesn't have `publish_to: none`).
  if yq -e '.publish_to // ""' pubspec.yaml | grep -q "none"; then
    LOG_MESSAGE "0" "[⏭️] Skipping publishing of \`$PACKAGE_PATH\` as it has \`publish_to: none\`."
    continue
  fi

  # Get `name` from `pubspec.yaml` using `yq`.
  PACKAGE_NAME=$(yq -r '.name' pubspec.yaml)

  # Get the first line that starts with `#`, and return the second element after splitting by space.
  # (It should be safe to optionally provide a release date after version number this way)
  CHANGELOG_VERSION=$(grep -m 1 "^#" "CHANGELOG.md" | cut -d ' ' -f 2)

  # Check whether it's a valid version number.
  # (https://dart.dev/tools/pub/pubspec#version)
  if [[ ! $CHANGELOG_VERSION =~ ^[0-9]+\.[0-9]+\.[0-9]+([-+][A-Za-z0-9.]+)*$ ]]; then
    LOG_MESSAGE "0" "[⏭️] Skipping publishing of \`$PACKAGE_NAME\` as \`$CHANGELOG_VERSION\` isn't a valid version number."
    continue
  fi

  # Create a tag for a release.
  TAG_NAME="$PACKAGE_NAME-v$CHANGELOG_VERSION"

  # Skip if it was modified, but such release (git tag) already exists.
  if [ $(git tag -l $TAG_NAME) ]; then
    LOG_MESSAGE "0" "[⏭️] Skipping publishing of \`$PACKAGE_NAME\` as \`$TAG_NAME\` already exists."
    continue
  fi

  # Update the version in `pubspec.yaml` file.
  if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' "1,/^version: .*/s/^version: .*/version: $CHANGELOG_VERSION/" pubspec.yaml
  else
    sed -i "1,/^version: .*/s/^version: .*/version: $CHANGELOG_VERSION/" pubspec.yaml
  fi

  # Configure `git`.
  # (https://github.com/actions/checkout/pull/1184)
  git config user.name "github-actions[bot]"
  git config user.email "41898282+github-actions[bot]@users.noreply.github.com"

  # Check if there any changes and push them.
  if ! git diff --quiet; then
    git add .
    git commit -m "Release \`$PACKAGE_NAME\` (\`$CHANGELOG_VERSION\`)"
    git push
  fi

  # Create a new tag and push it.
  git tag $TAG_NAME
  git push origin $TAG_NAME

  # Tag a new release if all prechecks succeeded.
  LOG_MESSAGE "32" "[✅] Created a tag \`$CHANGELOG_VERSION\` for \`$PACKAGE_NAME\`."
done <<<"$PACKAGE_PATHS"

LOG_MESSAGE "32" "[✅] Finished at $(date -u +"%Y-%m-%d %H:%M:%S")"
