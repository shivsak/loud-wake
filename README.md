# LoudWake

An Alarmy-style wake-up alarm for iOS 26+. Built on Apple's **AlarmKit** so it fires
reliably and breaks through silent mode / Focus, then routes you into the app and blasts
a loud loop until you solve a wake-up challenge (hard math, type-a-phrase, memory
sequence, or shake/steps). No snooze.

## Requirements

- **Xcode 26+** (install from the Mac App Store — Command Line Tools alone are not enough).
- A **physical iPhone on iOS 26** (AlarmKit + silent-mode breakthrough do not work in the Simulator).
- A **paid Apple Developer account**, signed in under Xcode → Settings → Accounts.

## Build

This repo ships source + an [XcodeGen](https://github.com/yonyz/XcodeGen) spec instead of
a checked-in `.xcodeproj`.

```bash
brew install xcodegen        # one time
cd ~/dev/LoudWake
xcodegen generate            # produces LoudWake.xcodeproj
open LoudWake.xcodeproj
```

Then in Xcode:

1. Select the **LoudWake** target → Signing & Capabilities → choose your **Team**
   (or set `DEVELOPMENT_TEAM` in `project.yml` and re-run `xcodegen generate`).
2. Do the same for the **LoudWakeWidget** target.
3. Confirm both targets have the **App Group** `group.com.loudwake.shared`.
4. Select your iPhone as the run destination and press **Run**.

### Manual fallback (no XcodeGen)

Create a new iOS App project (SwiftUI, iOS 26), add a Widget Extension target, then drag
in everything under `Sources/` (app target) and `Widget/` (widget target). Recreate the
capabilities/keys listed in `project.yml`: App Group `group.com.loudwake.shared`,
`UIBackgroundModes: audio`, `NSAlarmKitUsageDescription`, `NSMotionUsageDescription`.

## First-run test

1. Launch, grant the alarm and motion permissions.
2. Add an alarm 1–2 minutes out; enable math + one other challenge.
3. Lock the phone and flip the **silent switch on** → it should still ring loudly.
4. Tap **Solve to dismiss** on the alert → the app opens, audio keeps blaring, and the
   challenge screen blocks until solved → alarm goes silent.

## Notes / tradeoffs

- AlarmKit's system alert always includes a **Stop** button that can silence the alarm
  without the challenge — that is the one bypass and cannot be removed via the API.
- The exact AlarmKit symbol names are evolving; if the build flags an API mismatch,
  check Apple's AlarmKit docs / WWDC25 session 230 sample and adjust `AlarmScheduler.swift`.
