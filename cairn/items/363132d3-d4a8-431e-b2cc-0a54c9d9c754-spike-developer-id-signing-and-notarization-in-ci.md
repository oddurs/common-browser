---
id: 363132d3-d4a8-431e-b2cc-0a54c9d9c754
title: 'Spike: Developer ID signing and notarization in CI'
type: spike
status: done
milestone: v0.1
created: 2026-09-26
updated: 2026-09-27
closed_at: 2026-09-27
priority: p1
effort: s
area: release
---

## Question

What does it take to ship a signed, notarized app from GitHub Actions? This covers the Apple
Developer Program cost and account, storing the certificate and a notarytool API key as secrets,
and whether `codesign` and `xcrun notarytool` work with the runner's Xcode. What exactly does an
unsigned or ad-hoc app cost a user on current macOS?

## Timebox

Half a day. No certificate purchase until the owner decides.

## Answer

**Recommendation: buy the individual Apple Developer Program membership (99 USD a year) before
v0.2, and sign and notarize every release in the existing `release.yml` on `macos-15`.** Keep v0.1
ad-hoc signed as planned. Nothing in CI blocks this: the runner's tools cover every step, and the
only missing pieces are the account and six secrets. The decision is the owner's, and I have not
bought or signed up for anything.

**What an ad-hoc or unsigned app costs a user today**

- **Apple silicon runs nothing unsigned.** An ad-hoc signature is enough to run, "however, given
  that these signatures do not bear any valid identity, binaries signed this way cannot pass
  through Gatekeeper" ([Big Sur release notes](https://developer.apple.com/documentation/macos-release-notes/macos-big-sur-11_0_1-universal-apps-release-notes)).
- **Since macOS 15, Control-click → Open no longer bypasses Gatekeeper.** Users "need to visit
  System Settings > Privacy & Security" instead ([Apple, Aug 2024](https://developer.apple.com/news/?id=saqachfa)).
- **The first launch is blocked.** The user opens the app, sees it refused, then goes to Privacy &
  Security, clicks **Open Anyway** and confirms again. After that the app is saved as an exception
  and opens normally ([Safely open apps on your Mac](https://support.apple.com/en-us/102445)).
- **macOS 26 adds nothing new here.** The [macOS 26 release notes](https://developer.apple.com/documentation/macos-release-notes/macos-26-release-notes)
  do not mention Gatekeeper, so the macOS 15 flow applies.
- **The official Homebrew cask tap is closed to us unless notarized.** Casks in `homebrew/cask`
  "must pass Homebrew's Gatekeeper checks" ([Acceptable Casks](https://docs.brew.sh/Acceptable-Casks)).
  Homebrew quarantines every cask download so that Gatekeeper still checks it
  ([Homebrew security](https://docs.brew.sh/Homebrew-Security-and-Supply-Chain)). A cask in our
  own tap installs, but still hits the Open Anyway step.

**Account and cost**

- **Price:** 99 USD per membership year.
- **Individual enrollment is enough.** It needs no D-U-N-S number (only organizations do), and the
  owner's personal legal name is shown as the seller
  ([Enrollment](https://developer.apple.com/programs/enroll/)). I infer, but have not confirmed,
  that the same name appears on the certificate.
- **Who can create the certificate:** the Account Holder creates Developer ID certificates, up to
  five Developer ID Application certificates
  ([Create Developer ID certificates](https://developer.apple.com/help/account/certificates/create-developer-id-certificates),
  [Roles](https://developer.apple.com/help/account/access/roles)). An individual enrollee is the
  Account Holder.
- **Expiry does not strand old releases.** Apps signed while the certificate was valid keep running
  after it expires ([Certificates](https://developer.apple.com/support/certificates/)).

**What notarization requires of the build**

- a Developer ID Application signature on every executable, not an ad-hoc one;
- the hardened runtime (`codesign --options runtime`);
- a secure timestamp (`--timestamp`);
- no `get-task-allow` entitlement

([Notarizing macOS software](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution)).
Notarization accepts a zip, but the ticket cannot be stapled to a zip. So the order is: zip with
`ditto -c -k --keepParent`, submit with `notarytool submit --wait`, run `stapler staple` on the
`.app`, then zip it again for release
([Customizing the notarization workflow](https://developer.apple.com/documentation/security/customizing-the-notarization-workflow)).

**CI**

- **The tools are on the runner.** `notarytool` has shipped with Xcode since 13. The `macos-15`
  image defaults to Xcode 16.4 and also carries 26.x
  ([runner image](https://github.com/actions/runner-images/blob/main/images/macos/macos-15-arm64-Readme.md)).
  Command Line Tools alone have it too: `xcrun notarytool --version` prints 1.1.1 on a machine
  with no Xcode. `codesign` is part of macOS. Neither step needs an Xcode project.
- **Certificate:** export the Developer ID Application certificate and key as a `.p12` and store
  it base64-encoded as a secret. In the job:
  - create a temporary keychain with `security create-keychain`;
  - `security import … -f pkcs12`;
  - `set-key-partition-list -S apple-tool:,apple:`;
  - add the keychain to the search list.

  GitHub documents exactly this, and hosted runners are destroyed after the job
  ([GitHub: sign Xcode applications](https://docs.github.com/en/actions/how-tos/deploy/deploy-to-third-party-platforms/sign-xcode-applications)).
- **Notary credentials:** use a **Team** App Store Connect API key, passed as `--key`, `--key-id`
  and `--issuer`. Individual API keys cannot use `notaryTool`, and the `.p8` can be downloaded only
  once ([Creating API keys](https://developer.apple.com/documentation/appstoreconnectapi/creating-api-keys-for-app-store-connect-api),
  [TN3147](https://developer.apple.com/documentation/technotes/tn3147-migrating-to-the-latest-notarization-tool)).
  Apple does not document the minimum role. Developers report that the Developer role works
  ([forum](https://developer.apple.com/forums/thread/133063)), so try Developer before Admin.
- **Secrets:** six of them:
  - `DEVELOPER_ID_P12_BASE64`
  - `DEVELOPER_ID_P12_PASSWORD`
  - `KEYCHAIN_PASSWORD`
  - `NOTARY_KEY_P8_BASE64`
  - `NOTARY_KEY_ID`
  - `NOTARY_ISSUER_ID`

  Keep them in a `release` environment whose deployment rule allows only `v*` tags. Environment
  secrets reach only the jobs that reference the environment
  ([GitHub environments](https://docs.github.com/en/actions/reference/workflows-and-actions/deployments-and-environments)),
  so pull-request CI can never read them.

**Costs and risks**

- **Money:** 99 USD a year, renewed.
- **Two long-lived secrets.** If the certificate leaks, it can sign malware in the owner's name.
  Notarization's audit trail lets Apple revoke tickets for tampered builds.
- **Time:** each release waits for notarization, which Apple says usually takes less than an
  hour.
- **Name:** an individual account shows the owner's own name, not "Common Browser".

## Follow-up items

- `74812773` "Sign and notarize releases" (v0.2) implements this answer. Its proposal now carries
  the steps and the secret layout above. It still waits on the owner buying the membership.
- `5b3b46f3` "Install with Homebrew" now depends on `74812773`: without notarization, a
  cask install still stops at Open Anyway.
