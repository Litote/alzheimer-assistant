# Reminders — manual test plan

Manual checks for proactive reminders (local notifications + agent announcement).
Automated coverage: `tests/unit/test_reminders.py` (agent repo) and
`front/test/**/reminder*_test.dart`, `assistant_bloc_test.dart` (`reminderOpened` group).
See [`front/AI_CONTEXT.md`](../front/AI_CONTEXT.md#reminders-proactive-notifications) for the design.

## Prerequisites

- [ ] Agent deployed (or `make local-backend`) with `GET /reminders/upcoming`.
- [ ] iOS: `pod install` run in `front/ios`, "Time Sensitive Notifications" capability enabled in Xcode.
- [ ] A test account with access to the back-office (`events` table).
- [ ] App installed on **one Android phone and one iPhone**, signed in with the test account.

Tip: create events a few minutes ahead with `notify_before_minutes` = 1 or 2 to avoid waiting.

## 1. Server

| # | Test | Expected |
|---|------|----------|
| 1.1 | `curl -H "Authorization: Bearer <jwt>" "<ADK_BASE_URL>/reminders/upcoming?days=7"` with a one-off, a weekly and a no-time event | One entry per occurrence, sorted; `notify_at` in UTC = local time − `notify_before_minutes`; no-time event at 09:00 local |
| 1.2 | Same request without token, server with `REQUIRE_AUTH=true` | 401 |
| 1.3 | Cancel an event in the back-office, call again | Event no longer listed |
| 1.4 | `POST /run_sse` with `"reminder": {"event_id": "<id>", "date": "<today>"}` and no `new_message` | Agent text announces the event (title + time), short, no markdown |
| 1.5 | Same with an unknown / cancelled `event_id` | 404 |
| 1.6 | `/dev-ui/` or WS script: `setup.reminder` on `/run_live` | Agent speaks first and announces the event, conversation continues by voice |

## 2. Permissions (each platform)

| # | Test | Expected |
|---|------|----------|
| 2.1 | Fresh install, sign in | Notification permission prompt appears once |
| 2.2 | Android 14+: first sync | "Alarms & reminders" settings screen opens **once**; enable it |
| 2.3 | Refuse the notification permission, reopen the app | No crash, no repeated prompt; no notification shown |
| 2.4 | Existing user (onboarding already done) updates the app | Permission prompt appears at next launch |

## 3. Scheduling (each platform)

| # | Test | Expected |
|---|------|----------|
| 3.1 | Create an event in 5 min (`notify_before_minutes` = 2), open the app, close it, lock the phone | Notification at H−2 min with title and "À HH:MM - description", with sound |
| 3.2 | Same, with the phone idle for a while (Android Doze: unplugged, screen off) | Notification on time (exact alarm allowed) |
| 3.3 | Recurring daily event | Notified every day of the next 7 days |
| 3.4 | Edit the event time in the back-office, bring the app to the foreground | Notification moved to the new time (old one gone) |
| 3.5 | Cancel the event, bring the app to the foreground | Notification no longer fires |
| 3.6 | Airplane mode, bring the app to the foreground | Already scheduled notifications still fire |
| 3.7 | Android: reboot the phone before the notification time | Notification still fires |
| 3.8 | iOS: Focus mode / Do Not Disturb enabled | Notification breaks through (time-sensitive) |
| 3.9 | Sign out | No crash; (note whether notifications of the previous account still fire) |

## 4. Tapping the notification — text mode (default setting)

| # | Test | Expected |
|---|------|----------|
| 4.1 | App in background, tap the notification | App opens, agent announces the event (TTS), then returns to idle; mic button works for a follow-up question |
| 4.2 | App killed (cold start), tap the notification | Same as 4.1 once the app has started |
| 4.3 | App open and a conversation in progress, tap the notification | Current conversation stops, reminder is announced |
| 4.4 | Event cancelled after the notification was scheduled, tap it | No announcement. Known behaviour: the server answers 404 and the app shows "Connexion perdue." — decide whether this is acceptable |
| 4.5 | ElevenLabs voice enabled | Announcement uses the cloned voice |

## 5. Tapping the notification — audio mode (text mode off)

| # | Test | Expected |
|---|------|----------|
| 5.1 | App in background, tap the notification | Agent speaks first, then listens; answering by voice continues the conversation |
| 5.2 | Cold start from the notification | Same as 5.1 |
| 5.3 | LiveKit setting enabled | Reminder still announced (falls back to the WebSocket transport) |
| 5.4 | Android: no echo loop (agent does not answer itself) during the announcement | Agent stops after the announcement and waits |
| 5.5 | Event cancelled after the notification was scheduled, tap it | No announcement, normal listening session |

## 6. Wording (with the patient's caregiver)

- [ ] Announcement is short, gentle, does not say "you asked me".
- [ ] Medication reminders are understandable without context.
- [ ] Notification text readable on the lock screen.

## Results

| Date | Platform / OS | Mode | Failed tests | Notes |
|------|---------------|------|--------------|-------|
| | | | | |
