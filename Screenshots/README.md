# App Store screenshots

Two sets, so you can fill whichever slot App Store Connect shows:

- **`./` (root): 1320 × 2868** — 6.9" iPhone slot (the primary required size).
- **`6.5-inch/`: 1284 × 2778** — 6.5" iPhone slot (optional; use if ASC asks for it).

Upload the 6.9" set first; only use the 6.5" set if that slot is required/shown.

Suggested upload order:
1. `01-math.png` — the core idea: solve to wake up
2. `02-list.png` — your alarms
3. `03-typing.png` — type-a-phrase challenge
4. `04-edit.png` — configure time, repeat, challenges
5. `05-success.png` — the payoff

These were rendered by the DEBUG-only screenshot harness (`Sources/App/ScreenshotHarness.swift`),
which activates only when the app is launched with the `SCREENSHOT` environment variable.

## Regenerate

```bash
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
SIM=$(xcrun simctl list devices available | grep "iPhone 17 Pro Max" | grep -o "[0-9A-F-]\{36\}" | head -1)
xcrun simctl boot "$SIM"
xcodegen generate
xcodebuild -project LoudWake.xcodeproj -scheme LoudWake \
  -destination "platform=iOS Simulator,id=$SIM" -derivedDataPath /tmp/loudwake-dd build
xcrun simctl install "$SIM" /tmp/loudwake-dd/Build/Products/Debug-iphonesimulator/LoudWake.app
for s in math list typing edit success; do
  SIMCTL_CHILD_SCREENSHOT=$s xcrun simctl launch --terminate-running-process "$SIM" com.loudwake.app
  python3 -c "import time; time.sleep(4)"
  xcrun simctl io "$SIM" screenshot "Screenshots/$s.png"
done
```
