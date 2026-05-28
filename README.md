# Settle

> Shared money, zero awkwardness.

A calm, minimal expense-splitting app built for urban Indian friend groups. Add expenses in seconds, split however you like, and settle up with the fewest possible transfers.

Built with Flutter + Supabase. Currently in local-state mode — ready to wire to a real backend.

---

## Screenshots

> _Coming soon — run locally to see it in action._

---

## Features

- **Groups** — create a group for any occasion (trip, flat, dinner), invite friends via a shareable link
- **Expense entry** — custom numpad with quick-add buttons (+100, +500, +1k), equal or custom split, all in one sheet
- **Smart settlement** — greedy debt simplification algorithm finds the minimum number of transfers to clear a group
- **Dashboard** — net position across all groups, monthly spend, recent activity feed
- **Deep links** — `settle.app/join/:groupId?token=…` routes invite taps directly into the join flow
- **Notifications** — new expense alerts, weekly digest (Sunday 7pm), idle-group nudges when money has been sitting too long

---

## Stack

| Layer | Choice |
|---|---|
| Framework | Flutter 3 · Android-first, iOS-ready |
| Backend | Supabase (auth · postgres · realtime · storage) |
| State | Riverpod `StateNotifierProvider` |
| Navigation | go_router + deep link handling via `app_links` |
| Fonts | Inter (Google Fonts) |
| Notifications | flutter_local_notifications + timezone |

---

## Project structure

```
lib/
├── core/
│   ├── notifications/     # push alerts, weekly digest, idle nudges
│   ├── router/            # go_router config, deep link service, auth redirect
│   ├── supabase/          # supabase client init
│   ├── theme/             # colors, typography (Inter), AppTheme.dark
│   └── utils/             # currency_formatter, settlement_calculator, date_helpers
│
├── features/
│   ├── auth/              # login screen (OTP), auth provider
│   ├── groups/            # groups list, group detail, create sheet, join flow
│   ├── expenses/          # add expense sheet, expense detail sheet
│   ├── settlements/       # settle up sheet, settlement repository
│   └── dashboard/         # home tab, activity tab, profile tab
│
└── shared/
    ├── providers/         # auth_provider (session + test mode)
    └── widgets/           # FloatingNav (glassmorphic bottom bar)
```

---

## Running locally

```bash
flutter pub get
flutter run
```

The app boots in **local test mode** when Supabase keys are absent — sample group + expense data is seeded automatically so every screen is fully explorable without a backend.

---

## Roadmap

| Phase | Feature | Status |
|---|---|---|
| 1 | Auth (OTP sign-in, profile setup) | ✅ Done |
| 2 | Groups (create, invite link, join flow) | ✅ Done |
| 3 | Expense entry (numpad, equal/custom split, detail + delete) | ✅ Done |
| 4 | Balances & settlement (greedy algorithm, record payments) | ✅ Done |
| 5 | Dashboard (net position, monthly stats, activity feed) | ✅ Done |
| 6 | Notifications (expense alert, weekly digest, idle nudge) | ✅ Done |
| 7 | Supabase backend wire-up (real auth, persistent data) | ⏳ Next |
| 8 | Realtime sync (group members see updates live) | ⏳ Planned |

---

## Out of scope (MVP)

UPI integration · bank linking · receipt scanning · recurring expenses · budgets · expense categories · CSV/PDF export · FCM push · web version

---

## Contributing

This is a personal project. Issues and PRs welcome if you find a bug or have a small improvement.

---

## License

MIT
