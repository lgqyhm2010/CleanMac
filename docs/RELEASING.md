# Releasing CleanMac

CleanMac is distributed as a signed, notarized `.dmg`. This guide covers the
**one-time setup** and the **release flow**. The build itself is automated by
[`script/build_dmg.sh`](../script/build_dmg.sh) and by GitHub Actions
([`.github/workflows/release-dmg.yml`](../.github/workflows/release-dmg.yml)).

> `./script/build_dmg.sh --unsigned` creates an explicitly non-distributable
> preview for local validation. The default release path never falls back: it
> stops unless signing, notarization, stapling, and Gatekeeper checks all pass.

## Why signing + notarization?

macOS Gatekeeper blocks apps that aren't signed with an **Apple Developer ID
Application** certificate and notarized by Apple. An *Apple Development*
certificate (the kind Xcode creates for local runs) is **not** enough for
distribution.

## One-time setup

### 1. Enroll & create a Developer ID certificate

1. Join the [Apple Developer Program](https://developer.apple.com/programs/) (paid).
2. In **Xcode → Settings → Accounts → Manage Certificates**, add a
   **Developer ID Application** certificate (or create it in the Developer
   portal). It installs into your login keychain.
3. Verify it's there:
   ```bash
   security find-identity -v -p codesigning | grep "Developer ID Application"
   ```

### 2. Create notarization credentials

Create an **app-specific password** at <https://appleid.apple.com> (Sign-In &
Security → App-Specific Passwords), then store a reusable notarytool profile:

```bash
xcrun notarytool store-credentials CleanMacNotary \
  --apple-id "you@example.com" \
  --team-id "YOURTEAMID" \
  --password "abcd-efgh-ijkl-mnop"
```

`CleanMacNotary` is the profile name you'll pass as `NOTARY_PROFILE`.

## Building a release locally

```bash
# Uses your Developer ID cert + stored notary profile:
CLEANMAC_VERSION=1.0.0 CLEANMAC_BUILD_NUMBER=1 \
  NOTARY_PROFILE=CleanMacNotary ./script/build_dmg.sh --release
# -> dist/CleanMac.dmg  (signed, notarized, stapled)
```

To force a specific identity, also set `CODESIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)"`.

## Automated releases (CI)

Pull requests and pushes to `main` build an unsigned preview in a read-only,
secret-free job. Only a `v*` tag enters the publishing job. Add these repository
secrets (Settings → Secrets and variables → Actions):

| Secret | What it is |
|--------|------------|
| `MACOS_CERT_P12_BASE64` | Base64 of your exported Developer ID cert (`.p12`). Export from Keychain Access, then `base64 -i cert.p12 \| pbcopy`. |
| `MACOS_CERT_PASSWORD` | The password you set when exporting the `.p12`. |
| `MACOS_SIGN_IDENTITY` | e.g. `Developer ID Application: Your Name (TEAMID)`. |
| `APPLE_ID` | Your Apple ID email. |
| `APPLE_TEAM_ID` | Your 10-character team ID. |
| `APPLE_APP_PASSWORD` | The app-specific password from the setup above. |

Missing or invalid release secrets fail the tag job. No DMG is attached to a
GitHub Release unless signing, notarization, stapling, and Gatekeeper assessment
all succeed.

## Cutting a versioned release

```bash
git tag v1.0.0
git push origin v1.0.0
```

The tag triggers the workflow, which builds the DMG and attaches
`CleanMac.dmg` to the corresponding GitHub Release. Users download it from the
[Releases page](https://github.com/lgqyhm2010/CleanMac/releases).
