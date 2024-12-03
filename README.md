# Flutter Tools

A collection of **highly** opinionated and **highly** experimental tools for building side-projects in Flutter.

The majority of scripts assume that you are working on macOS and have utilities like `xcrun` (Xcode Command Line Tools) or `jq` installed.

**_If everything goes well_**, scripts should gracefully exit if some dependencies are missing or if you have something misconfigured.

Stuff may break if you override default BSD tools with GNU ones (e.g. `sed` is mapped to `gsed`, or `grep` calls `ggrep`).

It uses `fvm` if it's available, runs stuff with `flutter` directly if it's not available.

I didn't test it, but it probably doesn't work when using flavors.

## Constants

Scripts may use the following constants, that by default are commented-out (so you can export them from `~/.zshrc`):

- `APPLE_ISSUER_ID`
- `APPLE_KEY_ID`
- `APPLE_KEY_P8`

  Open App Store Connect, go to Users and Access -> Integrations -> App Store Connect API -> Team Keys and generate a new key. Yes, it has to be a **Team Key**, not _Individual Key_. Set `APPLE_ISSUER_ID` to Issuer ID that is visible on this page, `APPLE_KEY_ID` to Key ID, run `base64 -i ApiKey_XXXXXX.p8 | pbcopy` on your key to copy it to your clipboard as base64-encoded string, and paste it as `APPLE_KEY_P8`.

- `GOOGLE_SERVICE_ACCOUNT`

  Base64-encoded service account connected to your Google Play Console account.

  Go to Google Cloud -> IAM & Admin -> Service Account -> Create Service Account. Next, navigate to details and go to Keys -> Add key -> Create new key -> Key type (JSON) and download it. Run `base64 -i service-account.json | pbcopy` to copy it to your clipboard as base64-encoded string.

  Once you are done with that, add your service account's email to "Users and permissions" in Google Play Console.

  If you encounter any issues, feel free to ask Claude or ChatGPT for help.

## Available scripts

A short summary of each script. There is a giant comment at the top of each script if you want to learn more.

- `flutter-deploy`

  Releases an app from your local machine (to TestFlight in case of iOS, as a production draft for Android). Autoincrements build number and build name (with an option to set a custom build name if you feel like it's a good day to bump the major version). Uses `pubspec.yaml` for versioning. Does some sanity checks. [Removes dev_dependencies](https://github.com/flutter/flutter/issues/79261) from your production builds. Adds constants from `.env` file (very limited support though).

- `flutter-translate`

  Uses `git` to detect changed keys in `.arb` file and automatically regenerates them. Also uses `arb_utils` to order keys in a lexicographical order (from A to Z), and `arb_translate` to generate new translations with your favorite LLM provider.

- `connect2console`

  Copies your changelog for all languages from App Store Connect and uses it to populate the changelog in the latest draft in Google Play Console. Has some checks to ensure that we are copying stuff between the same version. Useful if you manage iOS releases in a third-party app like [Helm](https://helm-app.com) (or don't want to look at Google Play Console) and want to manage your Android releases with minimal effort. You can pass `--submit` to automatically submit a version to review.

## FAQ

- **Why shell scripts?**

  I didn't expect it to grow so much, if I were to do it again I would probably rewrite it in Go. I'm scared of bash scripts.

- **Why not Dart?**

  It requires activating it every time you change your SDK's version and that's annoying.

- **Why do you use Team Keys for Apple (and not app-specific password/individual keys)?**

  `altool` doesn't support Individual Keys and App Store Connect API doesn't support app-specific passwords, so the only thing that's left and doesn't require configuring two separate sets of secrets is a Team Key.

## License

Licensed under "do whatever you want, but don't sue me or expect it to work" license.

Alternatively, you can also consider it MIT licensed.

---

http://github.com/n-bernat/flutter-tools
