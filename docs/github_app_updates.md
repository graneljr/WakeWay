# GitHub Android updates

WakeWay checks the latest public GitHub release on Android startup and from
**More → App updates**. Each release must include an APK named
`WakeWay-android.apk`. The GitHub Actions workflow builds and attaches that APK
when a version tag starting with `v` is pushed.

## Prepare release signing

Android only installs an APK over an existing app when it has the same package
ID and signing key. Create one release key and keep a secure backup. Do not
commit the keystore or its passwords.

```sh
keytool -genkeypair -v \
  -keystore wakeway-upload.jks \
  -alias wakeway \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000
base64 -w 0 wakeway-upload.jks
```

Add the base64 output as the GitHub repository Actions secret
`ANDROID_KEYSTORE_BASE64`. Add these other Actions secrets too:

- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS` (the example above uses `wakeway`)
- `ANDROID_KEY_PASSWORD`
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `GOOGLE_SERVER_CLIENT_ID`

Use the same release key for every future APK. The first APK installed on a
device must also use this key. A debug build already installed from a developer
machine has a different key; uninstall it before installing the first release
APK.

## Publish an update

1. Increase the app version and Android build number in `pubspec.yaml`, for
   example `version: 1.0.1+2`.
2. Commit and push the change to GitHub.
3. Push a matching version tag:

   ```sh
   git tag v1.0.1
   git push origin v1.0.1
   ```

GitHub Actions builds the signed APK and publishes a GitHub Release. Keep the
repository public so installed apps can read the Releases API without shipping
a private access token in the app. Android users who accept the update are
sent to Android’s installer to confirm installation. iOS updates continue to
come from the App Store.
