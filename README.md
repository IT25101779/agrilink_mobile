# AgriLink AI 2.0 — Farmer Mobile App (Step 2)

## What's in this step
Three fully working screens, offline-first from the ground up:

1. **Crop Navigator** — enter land size + soil type → get rule-based crop recommendations → tap "Start Timeline" to generate a day-by-day milestone checklist, saved instantly to the device (works with **zero internet**).
2. **My Timelines** — lists all your active crops with live progress %, tap into any one to see the full checklist. Ticking a milestone updates local storage immediately and queues it for sync.
3. **Marketplace** — lists your harvest to the **real backend** you already have running (Step 1), shows a live AI price prediction as you type the crop name, and displays your existing listings with their tier (primary/secondary) and status.

Offline sync is real: `SyncService` watches the device's connectivity and automatically pushes any "pending" timeline the moment the phone reconnects — no user action needed (a manual "Sync Now" button is also on the Timelines screen for demo purposes, so judges can *see* it work on stage).

## Setup

1. **Install Flutter SDK**: follow docs.flutter.dev/get-started/install for your OS. Run `flutter doctor` and fix anything marked ✗.
2. From this folder, run:
   ```bash
   flutter pub get
   ```
3. **Make sure your Step 1 backend server is running** (`npm run dev` in the `agrilink-backend` folder) — the Marketplace screen talks to it live.
4. Open `lib/services/api_service.dart` and check the `baseUrl`:
   - Android emulator → keep `http://10.0.2.2:5000/api` (this already points to your PC's localhost)
   - Physical phone on the same WiFi → change it to `http://<your-pc-LAN-IP>:5000/api` (find your IP with `ipconfig` on Windows / `ifconfig` on Mac/Linux)
5. Run the app:
   ```bash
   flutter run
   ```

## Why no `build_runner` step
Normally Hive models need a code-generation step (`flutter pub run build_runner build`). I hand-wrote the `TypeAdapter` classes instead (`milestone_model.dart`, `timeline_model.dart`) so the app runs immediately with just `flutter pub get` — one less thing that can go wrong the night before your pitch.

## What's next
- Wire real Auth so `demo-farmer-001` becomes the actual logged-in user
- Add the `/timelines/sync-queue` backend route (mirrors the marketplace router you already have) so offline sync writes to MongoDB
- Disease Scanner screen (camera upload → CV microservice)
- Weather alert banners on the Timeline detail screen

## Logistics & Truck Tracking (Step 6)
Registration now asks "I am a…" Farmer or Truck Driver, with role-specific fields (district for farmers; vehicle registration + capacity for drivers). Drivers land on a completely separate **Driver Dashboard**: declare trip status (vehicle, capacity, destination hub), toggle live GPS tracking (pings the backend every 30 seconds while active), and confirm/reject incoming cargo requests from farmers.

Farmers get a new **Logistics** tab: search nearby trucks by destination hub, see live remaining capacity, and request shared cargo space — the driver then confirms or rejects it from their dashboard, which reserves that capacity automatically.

To test the full loop, you need **two accounts**: register one as a Truck Driver (start a trip, declare a destination like Dambulla), then register/login as a Farmer in a second browser/session (or log out and back in) and use the Logistics tab to find and request space on that truck.

## Crowdfunding (Step 7)
Open any active timeline from the "My Timelines" tab — you'll see a new funding card. Tap "Request Funding" to create a campaign (goal amount, return % offered to investors, description). The card then shows live funding progress. Investors pledge from the **buyer web portal's** new "Invest in Crops" tab (any registered buyer account can invest — see that project's README).

## Agri Assistant Chatbot (Step 8)
Tap the green chat bubble (bottom-right, floats over every farmer screen) to open the assistant. Pick English/Sinhala/Tamil from the dropdown in the top-right of the chat screen. It remembers conversation history per farmer and knows their current crop/day/next steps once a timeline exists (requires the backend's `ANTHROPIC_API_KEY` to be set — see that project's README).

## Forgot Password (Step 9)
"Forgot password?" link now sits under the password field on the Login screen. Enter your email, get a 6-digit code (check your inbox — or your backend terminal if email isn't configured yet, see that project's README), enter the code plus a new password, done.

## UI Polish Pass (Step 10)
Real design system now, not per-screen hardcoded colors:
- `lib/theme/app_theme.dart` — centralized colors, Google Fonts (Plus Jakarta Sans) typography, and component themes (buttons, inputs, cards, app bars) that cascade automatically to every standard Material widget
- Animated branded splash screen on launch
- Custom floating pill-style bottom nav bar with animated selection state
- Smooth fade+slide page transitions everywhere (`SmoothRoute`) instead of the default abrupt platform transition
- Staggered fade-in list/card reveals (`FadeSlideIn`)
- Shimmer loading placeholders and consistent empty states (`ShimmerBox`, `EmptyState`) — ready to drop into any screen still using a bare spinner
- Login/Register/Timeline screens fully redesigned; every other screen inherits the new look automatically since hardcoded color overrides were stripped

Run `flutter pub get` after pulling this update — `google_fonts` is a new dependency.

## Sinhala/English Language + Voice (Step 12)

**Language switching:** Tap the "EN / සිං" pill in the top-right of Login, Register, Home, or the Chat screen — the whole app switches instantly and remembers your choice (`lib/localization/app_locale.dart`). Core farmer-facing screens (Login, Register, Home navigation, Crop Navigator, Timeline List/Detail, Disease Scanner, Chat) are translated. Extending to Marketplace/Logistics/Driver screens is the same pattern — add a key to the `_translations` map and call `AppLocale.instance.t('yourKey')`.

**Voice input:** Tap the microphone icon next to the chat input box, speak your question, and it transcribes into the text field automatically (`lib/services/voice_service.dart`).

**Read-aloud:** Every assistant chat reply has a small speaker icon underneath it — tap to hear it read aloud. There's also an auto-read toggle (speaker icon, top-right of Chat) that reads every new reply automatically without tapping. Timeline milestones also have a speaker icon so a farmer can hear the day's task instead of reading it.

### Honest limitation — please read before your demo
**Sinhala speech-to-text (voice input) support is inconsistent across platforms.** It depends entirely on what speech recognition engine the device provides:
- **Native Android device** with Google's Sinhala voice input pack installed: works well
- **Chrome browser** (what you've been testing with via `flutter run -d chrome`): Chrome's Web Speech API has patchy-to-no Sinhala support as of now — voice input will likely only reliably work in **English** there
- **Text-to-speech (read-aloud) has much better Sinhala support** than speech recognition, since it uses locally installed voices rather than live recognition — this should work well even in Chrome if your OS has a Sinhala voice installed (Windows: Settings → Time & Language → Speech → Add voices)

**For your demo:** either demo voice input in English (reliable everywhere), or test read-aloud + Sinhala text UI on a real Android phone if you want to show Sinhala voice input working — don't rely on Chrome for that specific part of the demo.

### Android permissions (for a real device/APK build later)
When you eventually build a real Android APK (not just `flutter run -d chrome`), add this to `android/app/src/main/AndroidManifest.xml` inside the `<manifest>` tag:
```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
```

## Smart Reminders (Step 13)
Bell icon in the Home app bar (with a red badge showing pending count) opens the new Reminders screen. On every app open, `ReminderEngine` asks the backend to check each active timeline against live weather + nearby disease outbreaks + the schedule itself, and any new reminder pops up as a real local notification (allow notification permission when your device/browser asks).

Four reminder types:
- 🌧️ **Weather action** — e.g. "rain expected tomorrow, fertilize today or wait"
- 🐛 **Disease risk** — nearby outbreak detected; has an **Upload Photo** button that opens the Disease Scanner pre-filled with your crop and automatically links the result back to the reminder
- 🌾 **Harvest ready** — your crop's harvest milestone is within 3 days
- 📋 **Milestone due** — an overdue checklist step

Same honest limitation as before: this is real in-app + local notifications, not background push when the app is fully closed (that needs Firebase Cloud Messaging — a good "what's next" item to mention in your pitch roadmap).

## Comprehensive Crop Catalogue (Step 14)
Crop Navigator now has ~45 real, growable Sri Lankan crops across 6 categories: Vegetables, Fruits, Rice & Grains, Spices, Legumes, and Plantation Crops (`lib/services/crop_recommendation_service.dart`). Tap a category chip to filter.

Recommendations now also factor in **climate zone** (Wet/Intermediate/Dry), derived automatically from the district you entered at registration (`lib/services/climate_zone_service.dart` maps all 25 Sri Lankan districts). You'll see a badge like "Kandy — Wet Zone" confirming what's being used. If soil + zone together match nothing, it falls back to soil-only matches, then the full catalogue — so the screen is never empty.

Deliberately not a "every crop in the world" database — a global catalogue would include crops that can't actually grow in Sri Lanka, which wouldn't help anyone using this app.

## Sinhala Names + Real Photos (Step 15)
Every one of the ~45 crops now has a real Sinhala name (e.g. "Tomato · තක්කාලි") alongside English — shown in Crop Navigator recommendation cards and Timeline cards. Soil types are also bilingual ("Loamy (ලෝම පස්)").

**Photos are fetched live from Wikipedia's free public API** (`lib/services/crop_image_service.dart`) rather than hardcoded image files — no API key needed, images are public domain/CC-licensed, and results are cached in memory per session so the same crop isn't re-fetched every time its card scrolls into view. If a photo fails to load (offline, or an unusual crop name Wikipedia doesn't recognize), it gracefully falls back to a leaf icon — the screen never breaks or shows a broken-image icon.

Requires internet the first time a crop's photo loads (consistent with the rest of the app's online-optional design — the offline-first Timeline/checklist experience is unaffected).

## Full Sinhala Coverage + Suppliers & Rentals (Step 16)

**Sinhala everywhere now, including the "readout":** every stage of the crop timeline (Land Preparation, Sowing, Fertilizing, Harvest, etc.) has a real Sinhala translation now — both displayed on screen AND spoken aloud by the read-aloud button, based on whichever language you have selected. Also finished localizing Marketplace, Logistics, Driver Dashboard, Reminders, and Forgot Password — the whole app is Sinhala/English bilingual now, not just the core screens from before.

**New: Nearby Suppliers & Rentals screen** — accessible via a button in Crop Navigator (after getting recommendations) and a storefront icon in Timeline Detail's app bar. Shows verified seed/fertilizer/tool stores and equipment rental companies (tractors, tillers, harvesters) near the farmer's actual GPS location, filterable by type, with a one-tap **Call** button. This is genuinely new — it wasn't built before this step.

Remember to run the backend's `node scripts/seedSuppliers.js` once so this screen has real data to show.

## Seasonal Planting Calendar (Step 17)
New button in Crop Navigator opens a 12-month calendar (`lib/screens/seasonal_calendar_screen.dart`). Tap any month, see which of your 51 catalogue crops are best planted then, based on Sri Lanka's real Yala (Apr-Aug) and Maha (Sep-Mar) monsoon seasons. Fully bilingual, current month is highlighted automatically, reuses the same crop photos and Sinhala names from Crop Navigator.

Entirely offline/static — no backend or network call needed, since planting windows don't change day to day the way weather does.

## Dark Mode + Advanced Animations (Step 18)

**Dark mode:** sun/moon toggle on Login and Home screens (`lib/theme/theme_controller.dart`, persisted across restarts). A real dark ThemeData drives every screen's backgrounds, app bars, cards, buttons, and inputs automatically through Flutter's Theme system. Brand accent colors (forest green, gold, indigo, red) stay the same in both modes by design — they're saturated enough to read clearly either way, the same way most apps keep a colored badge or logo consistent across themes rather than muting it.

**Honest scope note:** a handful of custom-tinted info banners (like the crop-funding card, offline-sync banner) keep their light-green/light-indigo brand tint even in dark mode, matching how many production apps treat colored callout chips. Everything else — Scaffold backgrounds, AppBars, Cards, TextFields, buttons — properly switches.

**Advanced animations:**
- Bottom nav now has a continuously **sliding pill indicator** (not discrete per-icon recoloring) plus a spring-scale bounce on the selected icon
- **Confetti celebration** when a farmer completes the very last step of a crop timeline — a genuine payoff moment for finishing the whole season
- Animated sun/moon icon rotates and cross-fades on toggle

Run `flutter pub get` — `confetti` is a new dependency.

## Onboarding Walkthrough (Step 19)
First-time users (before ever logging in) now see a 4-page swipeable walkthrough (`lib/screens/onboarding_screen.dart`) covering the core loop: Crop Navigator → Disease Scanner + Agri Assistant → Marketplace → Funding/Suppliers. Fully bilingual, themeable, with animated page-dot indicators and a fade+slide entrance per page.

Shown exactly once — a `has_seen_onboarding` flag persists in SharedPreferences, checked by the Splash Screen. Skip button available on every page. Great to lead your pitch video with, since it explains the app faster than you narrating over a live demo.

## Profile Screen + Broader Polish (Step 20)

**New Farmer Profile screen** (tap the person icon, top-right of Home) — finally surfaces the credit score system that's been running invisibly since crowdfunding was built: an animated circular gauge (0-1000, color-coded Building/Good/Excellent), active vs. completed timeline counts, and a Settings section (dark mode + language, both live-toggleable) with a confirm-before-logout dialog.

**Broader skeleton loading** — Logistics, Suppliers, and Reminders now show shimmer-card placeholders while loading instead of a bare spinner, matching the pattern already used elsewhere.

**Micro-interactions** — haptic feedback on: bottom nav taps (light selection click), completing a milestone (light tap), completing an entire timeline (medium impact, paired with the confetti), and starting a new crop timeline (medium impact). Small, but it's the difference between an app that feels "clicked" and one that feels "touched."
