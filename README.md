# Gold Apex Signals

A dark-themed, gold-accented Flutter app for posting and unlocking gold & forex
trading signals, with a coin wallet and manual WhatsApp payment verification
priced in UGX.

## Run it

```bash
flutter pub get
flutter run
```

Requires Flutter 3.24+ (Dart 3+). Tested layout targets phone screens; also
runs fine on web/desktop for quick previewing (`flutter run -d chrome`).

## What's implemented (UI + in-memory state)

- **Feed** — signals list, locked signals blurred with an "Unlock for 50
  coins" CTA (`lib/screens/feed_screen.dart`, `lib/widgets/blur_lock_overlay.dart`)
- **Signal detail** — full analysis + chart image slot, same blur/unlock logic
- **Wallet** — coin balance, active plan status, UGX pricing table (5-day /
  monthly / 3-month / lifetime / single-unlock), reference-ID generation,
  and a WhatsApp deep link pre-filled with the payment details
  (`lib/screens/wallet_screen.dart`)
- **Performance** — public win-rate / track record screen
- **Admin panel** (`lib/screens/admin/`) — post a signal (text + optional
  screenshot toggle), approve/reject pending WhatsApp payments, add/remove
  admins
- **Reference ID scheme** — `5DAYS######`, `MONTHLY######`, `3MONTHS######`,
  `LIFETIME######`, `STRAIGHT######` (single unlock), generated in
  `AppState.generateReferenceId()`

All data currently lives in `lib/state/app_state.dart` as an in-memory
`ChangeNotifier` seeded with demo signals, so you can click through the whole
flow immediately with no backend.

## Wiring it up to Supabase (next step)

`AppState` was written so this swap is mostly local to that one file:

1. Create tables: `users`, `signals`, `unlocks`, `payment_requests`, `admins`
   (columns match the fields already on the Dart models in `lib/models/models.dart`).
2. Replace the seeded lists with Supabase queries/`.stream()` calls.
3. Swap `submitPaymentRequest` / `approvePayment` to write/update rows instead
   of mutating local lists.
4. Add Supabase Auth for real sign-up/login (currently `currentUsername` and
   `isAdmin` are hardcoded at the top of `AppState` for demo purposes).
5. Wire the screenshot upload button in `post_signal_tab.dart` to
   `image_picker` + Supabase Storage, and save the returned URL to `imageUrl`.
6. Add Firebase Cloud Messaging for push notifications on new signals /
   payment approval / plan expiry.

## Editable constants

- WhatsApp number: `kWhatsAppNumber` in `lib/screens/wallet_screen.dart`
- Plan pricing/duration: `PlanTypeX` extension in `lib/models/models.dart`
- Coin unlock cost: `TradingSignal.coinCost` in `lib/models/models.dart`
- Brand colors: `AppColors` in `lib/theme/app_theme.dart`
