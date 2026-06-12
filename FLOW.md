# Screenshot capture flow

Real captures from the iOS Simulator via an integration-test driver (no mockups).

## Steps

1. Boot the simulator:
   ```bash
   xcrun simctl boot "iPhone 17 Pro"
   open -a Simulator
   ```
2. Scaffold the iOS platform folder (lib-only project) and get dependencies:
   ```bash
   flutter create . --platforms=ios --project-name flutter_singbox_vpn
   flutter pub get
   ```
3. Drive the screenshot test:
   ```bash
   flutter drive \
     --driver test_driver/integration_test.dart \
     --target integration_test/screenshot_test.dart \
     -d "iPhone 17 Pro"
   ```
4. Build the demo GIF from the PNGs:
   ```bash
   cd screenshots
   ffmpeg -y -framerate 1 -pattern_type glob -i '*.png' \
     -vf "scale=320:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" \
     -loop 0 demo.gif
   ```

PNGs + `demo.gif` are written to `screenshots/` and embedded in `README.md`.

## How it works

- `test_driver/integration_test.dart` - `integrationDriver(onScreenshot:)` writes each PNG to `screenshots/<name>.png`.
- `integration_test/screenshot_test.dart` - pumps `VpnScreen` inside a dark-themed `MaterialApp`, then walks the connect UI:
  1. `01-disconnected` - the default idle tunnel state with the status card, server dropdown, and the kill-switch / P2P-block toggles.
  2. `02-server-picker` - taps the `DropdownButtonFormField` to reveal all exit locations (New York, Frankfurt, Tokyo).
  3. `03-policy-controls` - selects Germany - Frankfurt and toggles the kill switch off to show the policy controls reacting.
- Each capture calls `binding.convertFlutterSurfaceToImage()` + `binding.takeScreenshot('NN-name')`.
