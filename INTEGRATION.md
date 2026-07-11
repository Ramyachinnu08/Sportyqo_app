# Backend Integration (branch: backend-integration)

This branch wires the SportyQo Flutter app to the real backend
(https://github.com/dhanuvagman006/BackendforSportsApp) and removes mock data
from the wired screens.

## Run it

1. **Start the backend** (from the backend repo):
   ```bash
   docker compose up --build      # API on http://localhost:8000
   ```
2. **Fetch packages** (new deps: `http`, `shared_preferences`):
   ```bash
   flutter pub get
   ```
3. **Run the app:**
   ```bash
   # iOS simulator / desktop / web — localhost works out of the box
   flutter run

   # Android emulator — host localhost is 10.0.2.2 (already the default
   # on Android), or point at any server explicitly:
   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/v1
   ```
   Android cleartext HTTP + INTERNET permission are enabled in the manifest
   for development.

## The API layer (`lib/api/`)

- **`api_config.dart`** — base URL (dart-define override), `TokenStore`
  (persists the JWT pair; the refresh token ROTATES — the newest one returned
  by the server is always stored), `Session` (current-user cache).
- **`api_client.dart`** — bearer auth on every call; on `401 TOKEN_EXPIRED`
  performs a single-flight refresh and retries once; refresh failure
  (`TOKEN_REUSED` etc.) clears the session. Backend error envelope
  `{error:{code,message,field}}` surfaces as typed `ApiException`.
- **`services.dart`** — Auth/User/Player/Coach/League/Feed/Notification/Config
  services covering the endpoints the screens use.
- **`mappers.dart`** — converts API JSON into the map shapes the existing
  widgets already render (icon-name→IconData, hex→Color, ISO→"2h ago").
- **`ui_helpers.dart`** — error snackbars + button spinner.

## Wired to the real API (mock data removed)

**Auth & onboarding — complete:**
register (player + coach), login with role toggle (`ROLE_MISMATCH` handled),
coach OTP send/verify (server is the only gate now; a `dev_code` hint shows in
non-production), player profile (dob/location), sport selection with the
**server-minted Player ID** (client-side `millisecondsSinceEpoch` generator
deleted), coach profile completion, coach sport, splash **session auto-restore**
(rotating refresh token), logout (revokes the refresh token server-side).

**Player:**
home dashboard (name, Player ID, Qo score + monthly delta, active league,
upcoming match), notifications (list / mark read / mark all), All Matches,
Exit Team (`DELETE /leagues/{id}/membership`), **Join League** (code lookup via
`GET /leagues/by-code/{code}` → team picker with live player counts → real
join with `ALREADY_MEMBER`/`LEAGUE_FULL`/`INVALID_CODE` handling; numeric
keypad replaced with a text field since real codes look like `FALC-16-24`),
Dugout feed (server-side tabs + search, optimistic like/unlike reconciled with
server counts).

**Coach:**
create league (**league code now comes from the server response** — the
client-side code generator was deleted; mock seed team names removed),
notifications.

## Still on mock data (next passes)

These screens still render their inline fixtures and need the same
"load → map into existing keys" treatment (services for all of them already
exist in `lib/api/services.dart`):

- `coach_leagues_screen.dart` (league card + Teams/Matches/Standings
  sub-screens) → `LeagueService.myLeagues/detail/matches`
- `select_match_screen.dart` → `LeagueService.matches/createMatch`
- `select_players_screen.dart` → `LeagueService.players` +
  `LeagueService.submitPoints` (send the `Idempotency-Key`; the service
  handles the header)
- `coach_performance_screen.dart` → `CoachService.roster/addPlayer/recommend`
- `qo_score_card_screen.dart` → `PlayerService.qoScore` + `ConfigService.cardTiers`
- `performance_screen.dart` → `PlayerService.performance`
- `playbook_screen.dart` / `coach_playbook_screen.dart` →
  `PlayerService.playbook` / `CoachService.playbook` + `FeedService.createPost`
- `coach_dugout_screen.dart` → same wiring as the player dugout
- `coach_certification_screen.dart` → `CoachService.certification/submitCertification`
- `profile_screen.dart` (labels) / `coach_profile_screen.dart` /
  `coach_home_screen.dart` header stats → `UserService.me`,
  `CoachService.dashboard`
- `_LeagueDetailScreen` standings inside `home_screen.dart` →
  `LeagueService.detail`
- Sport-picker icons in `select_sport_screen.dart` are static design assets
  (ibb.co) — swap for bundled assets or a CDN when available.

## Smoke test (against a local backend)

1. Choose Player → Sign up → profile → pick Cricket → real `P26…` ID appears.
2. Choose Coach (second account) → Sign up → OTP (use the dev code shown) →
   profile → Create League → note the server code on the success screen.
3. Player → Join League → enter that code → pick a team → join → dashboard
   shows the league; coach gets a "player joined" notification.
4. Dugout tab loads the live feed; like a post and re-open — the count sticks.
