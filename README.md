# Healing

Healing is a native SwiftUI watchOS app for personal Apple Watch deployment. It shows calming local quotes, schedules gentle local notification pulses, and includes a WidgetKit complication that can keep a short quote visible on the watch face.

## Project Structure

```text
Healing.xcodeproj
Healing/
  HealingApp.swift
  ContentView.swift
  Assets.xcassets/
Healing Watch App/
  HealingApp.swift
  ContentView.swift
  Services/
    NotificationManager.swift
    SettingsManager.swift
  ViewModels/
    QuoteViewModel.swift
  Views/
    QuoteCardView.swift
    SettingsView.swift
  Assets.xcassets/
Healing Widget/
  HealingWidgetBundle.swift
  HealingQuoteWidget.swift
  Info.plist
Shared/
  Quote.swift
  QuoteStore.swift
  NotificationFrequency.swift
  Quotes.json
```

`Shared/Quotes.json` is included in both the watch app target and the widget extension target through the Xcode project. The quote storage source is not duplicated.

## Features

- Random quote display with themed background, foreground, and accent colors.
- Smooth quote transitions and a `New Quote` action.
- Favourite toggle stored locally.
- Settings for notification frequency, notification enablement, randomise-on-launch, show-author, and resetting favourites.
- Local notification pulses using `UserNotifications`.
- WidgetKit complication support for `accessoryCircular`, `accessoryRectangular`, `accessoryInline`, and `accessoryCorner` where supported by the active SDK.
- No backend, no cloud services, and no third-party dependencies.

## Build Instructions

1. Open `/Users/kartikeyachaauhan/Documents/New project/Healing/Healing.xcodeproj` in Xcode.
2. Select the `Healing Watch App` scheme.
3. In Signing & Capabilities, choose your Apple Account team for:
   - `Healing`
   - `Healing Watch App`
   - `Healing Widget`
4. Confirm bundle identifiers are unique for your Apple Account if Xcode reports a signing conflict.
5. Build with `Product > Build`.

This workspace was validated with Xcode's bundled `xcodebuild` because the global `xcode-select` path on this machine points at Command Line Tools. Building from the Xcode app uses the same Xcode toolchain.

## Deploy To Your Apple Watch

1. Pair your Apple Watch with your iPhone.
2. On Apple Watch, enable Developer Mode if Xcode asks for it:
   - Settings > Privacy & Security > Developer Mode.
   - Restart the watch when prompted.
3. In Xcode, select your paired Apple Watch as the run destination.
4. Press Run.
5. Accept any trust or developer prompts on iPhone or Apple Watch.

This is direct personal deployment. You do not need to publish the app to the App Store.

## Add The Complication

1. Long-press the watch face.
2. Tap Edit.
3. Swipe to Complications.
4. Select a complication slot.
5. Choose `Healing Quote`.
6. Press the Digital Crown to save.

Tapping the complication opens the Healing watch app.

## Notification Pulses

The app asks for notification permission on first launch. In Settings, choose a frequency and tap `Schedule Pulses`.

Supported schedules:

- Every 2 hours
- Every 15 minutes
- Every 4 hours
- Every 6 hours
- Morning only
- Evening only
- Disabled

`Clear Scheduled Notifications` removes Healing's pending local notification requests.

## watchOS Limitations

- Arbitrary background execution is not available for this type of watchOS app. Healing cannot wake up whenever it wants to run code in the background.
- Local notifications must be scheduled ahead of time. watchOS may delay, group, or suppress delivery based on Focus, notification settings, power state, wrist detection, and system policy.
- Custom vibration patterns cannot be triggered in the background. Local notifications use Apple-controlled notification haptics and user sound/haptic settings.
- WidgetKit timelines are not live timers. The widget supplies dated entries, and watchOS decides when to reload or preserve an older entry to save power.
- Complication color rendering is family and watch-face dependent. WidgetKit may tint, simplify, or ignore some theme colors.

## Troubleshooting

- If Xcode cannot find your watch, unlock the iPhone and watch, keep them near each other, and reopen the run destination picker.
- If signing fails, set a unique bundle identifier under each target and reselect your Apple Account team.
- If notifications do not appear, check Apple Watch Settings > Notifications and any active Focus mode.
- If the complication does not update immediately, wait for WidgetKit's timeline reload or remove and re-add the complication.
- If command-line builds fail with `xcode-select`, run Xcode's build button, invoke `/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild`, or select full Xcode with `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`.
