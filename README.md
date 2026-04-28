# Ask AI

![coverage][coverage_badge]
[![style: very good analysis][very_good_analysis_badge]][very_good_analysis_link]
[![License: MIT][license_badge]][license_link]

A minimal Flutter chat app that simulates a conversation with an AI assistant. Messages are sent over a WebSocket and the server's echoed response is rendered as the assistant reply, complete with a typewriter reveal.

Built as a take-home for the Zapia Senior Flutter Developer Challenge.

## Demo

A short screen recording of the finished app lives at [`demo.mov`](./demo.mov) in the repo root.

---

## Table of Contents

1. [Getting Started](#getting-started-)
2. [Architecture & Decisions](#architecture--decisions-)
3. [Assumptions & Constraints](#assumptions--constraints-)
4. [Features](#features-)
5. [Running Tests](#running-tests-)
6. [Bloc Lints](#bloc-lints-)
7. [Working with Translations](#working-with-translations-)

---

## Getting Started 🚀

### Prerequisites

- **Flutter SDK pinned via [fvm][fvm_link]** to `3.41.7` (see `.fvmrc`). Prefix Flutter/Dart commands with `fvm` so the pinned SDK is used.
- An iOS simulator / physical iOS device, or an Android emulator / physical Android device. Other platforms are intentionally not supported (see [Assumptions & Constraints](#assumptions--constraints-)).

### Environment files

Each flavor reads compile-time constants from a JSON env file at the project root:

| Flavor      | File            | Provides      |
| ----------- | --------------- | ------------- |
| development | `env-dev.json`  | `WS_ENDPOINT` |
| staging     | `env-stg.json`  | `WS_ENDPOINT` |
| production  | `env-prod.json` | `WS_ENDPOINT` |

Values are read inside `main_<flavor>.dart` via `String.fromEnvironment` and supplied at build time with `--dart-define-from-file=env-<flavor>.json`.

> **Why are these committed?** The only env value the challenge needs is `WS_ENDPOINT`, which points at the public echo server (`wss://echo.websocket.org`) — there is no credential to protect. Committing the files lets a reviewer clone-and-run with zero setup. In a production app these would be `.gitignore`d and sourced from a secret manager; the pattern is in place for that, the values just don't happen to be sensitive here.

### Run

Three flavors, each with its own entrypoint and env file:

```sh
# Development
$ fvm flutter run --flavor development --target lib/main/main_development.dart --dart-define-from-file=env-dev.json

# Staging
$ fvm flutter run --flavor staging --target lib/main/main_staging.dart --dart-define-from-file=env-stg.json

# Production
$ fvm flutter run --flavor production --target lib/main/main_production.dart --dart-define-from-file=env-prod.json
```

VSCode users can also use the bundled launch configurations in `.vscode/launch.json` (`Launch development`, `Launch staging`, `Launch production`).

---

## Architecture & Decisions 🏗️

The app is structured as a Flutter feature-folder layout backed by a small workspace of local packages. Each architectural decision below is paired with the alternative I considered and why I did not take it.

### Workspace package layout

Domain code is split into local packages under `packages/`, consumed by the app via `pubspec.yaml` path dependencies.

| Package                                                    | Role                                                                                                                                                                 |
| ---------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `packages/app_ui`                                          | Design system tokens (spacing, radii, typography, theme) and reusable cross-feature widgets. Re-exports `flutter/material.dart` so consumers import a single barrel. |
| `packages/chat_client/chat_client`                         | Transport-agnostic `ChatClient` interface, domain models (`ChatMessage`), and the `ChatClientException` hierarchy. No transport dependency — pure contract.          |
| `packages/chat_client/web_socket_chat_client`              | WebSocket-backed `ChatClient` implementation. Wraps `web_socket_channel` and maps transport errors onto the domain exception hierarchy.                              |
| `packages/chat_repository`                                 | Bridges a `ChatClient` to the feature blocs/cubits. Feature code depends on this — never directly on a `*_client` package.                                           |
| `packages/conversations_client/conversations_client`       | Transport-agnostic `ConversationsClient` interface and domain models for conversations, messages, folders.                                                           |
| `packages/conversations_client/drift_conversations_client` | drift (SQLite) implementation of `ConversationsClient`. Owns the schema, migrations, and reactive `watch*` streams.                                                  |
| `packages/conversations_repository`                        | Bridges `ConversationsClient` to feature blocs/cubits.                                                                                                               |

**Why split the contract from the implementation?** A pure interface package lets me test feature code against in-memory fakes without dragging in `web_socket_channel` or `drift`. It also leaves the door open to swapping transports (e.g. a real LLM endpoint) without touching anything above the repository layer.

### State management: bloc

I use `bloc` / `flutter_bloc` and enforce `bloc_lint` recommended rules. The chat surface uses a `Bloc` (event-driven; many transitions) while the drawer uses a `Cubit` (small set of orchestrated mutations). `AppBloc` owns app-wide state (active conversation id, transient errors, streaming id).

**Alternative considered.** Riverpod or Provider with `ChangeNotifier`. I picked bloc because I have been working with it for years and know it deeply — its conventions, edge cases, and testing patterns are second nature to me, which let me move fast and ship a polished result inside the take-home's time budget. The conversation lifecycle (activation, send, echo, streaming completion, transient error) also happens to be a natural fit for bloc's typed events and deterministic transitions, but the deciding factor was depth of experience.

### Persistence: drift (SQLite)

Local persistence uses [drift][drift_link] over SQLite, exposing reactive `watch*` streams that feed directly into bloc/cubit state.

**Why drift over `hydrated_bloc` / `hive`?**

- **Cascade deletes are native.** Deleting a folder deletes every conversation in it, and deleting a conversation deletes its messages — implemented as `ON DELETE CASCADE` in SQL. With a key-value store, every cascade is a manual fan-out and a chance to leak orphan rows.
- **Reactive `watch()` queries.** Drift's `watchMessages(conversationId)` emits a fresh snapshot on every relevant write, so the UI is always a render of the current database state. There is no separate in-memory cache to keep in sync.
- **Structured queries.** Folders, conversations, messages, and a single-row `app_metadata` table for the last-active conversation key. A relational schema models this far more cleanly than nested JSON blobs.

### Per-conversation WebSocket sockets

Each conversation owns its own `ChatClient` instance, lifecycle-managed by a `ChatRepositoryRegistry` provided at the app level. Echoes return on the same socket they were sent on, so message-to-conversation routing is **structural** — the socket _is_ the conversation channel.

**Alternative considered: a single shared socket with FIFO routing.** Cheaper on socket count, but it requires every outgoing message to be tagged with the conversation it belongs to, and every incoming echo to be matched back via that tag. The echo server doesn't preserve metadata, so I'd be tagging messages in the message body — fragile and brittle. The per-conversation socket model trades a small number of extra sockets for routing that cannot get out of sync.

### Drawer-based navigation

Conversation history lives inside a left-edge navigation drawer, mirroring the ChatGPT and Claude mobile apps. The active chat is the main screen; the drawer slides in to show history. Folders, the new-conversation CTA, and all conversation/folder context menus live inside the drawer.

**Alternative considered: a separate "history" page reachable via push navigation.** Functional, but it forces the user to leave the chat to switch chats. The drawer pattern is the de facto standard for AI chat apps and keeps the active conversation as the focal point of the app at all times.

### Typewriter is a view-layer effect

When an echo arrives, it is persisted in full immediately — but the active chat reveals it character-by-character via a `TypewriterText` widget. `streamingMessageId` lives on `AppBloc.state` and is **only set when the echo's `conversationId` matches the active id**, so:

- Switching conversations clears `streamingMessageId` (no replay on return).
- Background-arrived echoes (echo for a conversation the user isn't viewing) appear as plain text on return.
- Persisted state contains only the final text — there is no "streaming" flag in the database.

**Alternative considered: persist a `streaming` flag and replay on app restart.** That would lie about what's persisted (the echo arrived in full; nothing is actually streaming) and would replay typewriter effects on cold start, which is jarring.

### App-orchestrated vs. cubit-orchestrated CRUD

Both `AppBloc` and the page-scoped `ConversationsCubit` mutate persistence. The split is principled: anything that touches **app-wide state** (active conversation id, the chat repository registry, app-level transient errors) is orchestrated by `AppBloc`. Everything else is on the cubit.

| Action                                  | Orchestrated by      | Why                                                                                                                           |
| --------------------------------------- | -------------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| Activate conversation                   | `AppBloc`            | Mutates `activeConversationId`, persists last-active metadata.                                                                |
| First message in a brand-new chat       | `AppBloc`            | Atomically: auto-title + create row + append message + activate id + obtain repo + send. Failures map to `AppTransientError`. |
| Subsequent sends                        | `ChatBloc`           | Scoped to one conversation; no app-wide state is touched.                                                                     |
| Delete conversation                     | `AppBloc`            | Disposes the per-conversation socket via the registry and clears the active id if needed.                                     |
| Delete folder (cascading)               | `AppBloc`            | Same as above for _every_ conversation inside the folder; the bloc receives the cascading ids from the cubit's call site.     |
| Rename / move conversation, folder CRUD | `ConversationsCubit` | Pure persistence calls; no app-wide state is touched.                                                                         |

### Empty conversations are not persisted

`activeConversationId == null` is a first-class state representing "new chat in progress." The conversation row is created on the first user send (via `AppFirstMessageSubmitted`). This keeps history free of empty stubs created by users who tap "New conversation" and then change their mind.

### Auto-titling

The default conversation title is the trimmed first 40 chars of the user's first message, with a `…` suffix when truncated. Implemented as `AppBloc.autoTitle`. Users can rename freely afterwards.

### Last-active resume

A single-row `app_metadata` table stores the last active conversation id under a fixed key. Loaded on `AppStarted` and persisted on every `AppConversationActivated` / `AppNewConversationRequested`. Reopening the app drops the user back into the conversation they were last in.

### Long-press → floating context menu

All row-level actions on conversations and folders live behind a long-press gesture that opens a floating context menu **anchored to the row**, not a modal bottom sheet. This is the iOS-native context menu pattern (and matches iMessage / WhatsApp / Notes), keeps the menu visually tethered to its target, and reuses one component across folders and conversations.

**Alternative considered: swipe-to-action.** More efficient (one motion), but it requires per-row dismissibles, undo affordances, and significantly more test surface for marginal UX gain at this scale.

### Three flavors, one bootstrap

`lib/main/main_{development,staging,production}.dart` all delegate to `bootstrap()` in `lib/main/bootstrap/bootstrap.dart`, which wires up `Bloc.observer` and `FlutterError.onError` before running `App`. Compile-time env values are exposed via the `Environment` value type. Cross-flavor setup goes inside `bootstrap`, not inside individual `main_*.dart` files.

---

## Assumptions & Constraints 📋

### Assumptions about the echo server

- **The echo returns the entire message in a single frame**, not token-by-token. True LLM-style token streaming therefore isn't possible against this backend — the typewriter is a per-character reveal of the already-received text. The character cadence (~30ms/char) is a sensible default tuned for a believable feel.
- **No authentication.** The endpoint is public.
- **64KB message ceiling.** Surfaced as `MessageTooLargeException` and rendered as a snackbar in the chat view.
- **10-minute inactivity timeout.** The repository registry handles reconnect on demand — a stale socket simply gets re-established on the next send.

### Product assumptions

- **Single-device, local-only persistence.** No multi-device sync, no cloud backup. Drift is the source of truth.
- **No accounts, no auth.** A single anonymous user per device.
- **Empty conversations are not history.** A "new conversation" with zero sends doesn't show up in the drawer until the user sends something.
- **Folders are flat.** Nesting was rejected (see [Bonus #3](#bonus-3--folders-folder-crud-and-conversation-move) for rationale).
- **Folder delete cascades destructively.** Deleting a folder deletes every conversation inside it. The confirmation dialog names the count to mitigate the risk.

### Engineering constraints

- **Platforms: iOS and Android only.** macOS / Windows / Linux / web platform folders have been removed deliberately. Don't reintroduce them.
- **Flutter SDK is pinned** to `3.41.7` via `.fvmrc`. Always run with `fvm`.
- **Lints:** `very_good_analysis` + `bloc_lint` recommended rules. `public_member_api_docs` is disabled; `lib/l10n/gen/*` is excluded.
- **Localization:** ARB-based (`lib/l10n/arb/`). User-facing strings must go through `context.l10n`.
- **Test coverage: 100%, enforced.** The full test suite — across the app and every workspace package — runs at 100% line coverage. Every new line of production code ships with a test, and coverage is not allowed to regress. CI runs with `very_good test --coverage --min-coverage 100`.

---

## Features ✨

### Required #1 — Real-time chat

The user types into a composer at the bottom of the active chat and taps send (or presses the keyboard's send action). The text is sent over the conversation's dedicated WebSocket. When the server's echoed response arrives, it is persisted as an assistant message and revealed to the user via the typewriter (see Bonus #1). All transient failures — too-large messages, connection failures, send failures — are surfaced as snackbars and the conversation remains in a sendable state.

Code: `lib/chat/`, `packages/chat_client/{chat_client,web_socket_chat_client}`, `packages/chat_repository`.

### Required #2 — Conversation history

Past conversations are listed in a left-edge drawer. Tapping a row resumes that conversation. The header CTA inside the drawer starts a new conversation. Messages persist locally across app restarts via drift-backed SQLite, and the app reopens directly into the last-active conversation.

Code: `packages/conversations_client/{conversations_client,drift_conversations_client}`, `packages/conversations_repository`, `lib/app/`, `lib/chat/`, `lib/conversations/`.

### Bonus #1 — Typewriter streaming + in-progress send button

When an assistant response arrives, it is revealed character-by-character rather than appearing all at once. The reveal always plays out in full — there is no fast-forward or skip. While a response is in flight, the composer's send button is replaced by an animated in-progress indicator that persists until the reveal completes.

**Rationale.** A typewriter reveal and an in-progress affordance are de facto standards for AI chat (ChatGPT, Claude, Gemini). They sell the "AI is thinking" illusion and soften the otherwise-jarring instant echo. Replacing the send button with the indicator avoids spending a separate bonus slot on a dedicated typing-indicator bubble.

**Tradeoffs.**

- True token-by-token streaming would more faithfully mimic a real LLM, but the WebSocket echo returns the full message in a single frame — per-character animation is the closest I can get without faking server behavior.
- A standalone "three dots" typing-indicator bubble (à la iMessage) is a more conventional pattern, but it would have consumed a full bonus slot for marginal benefit over the in-line button animation.
- The typewriter is view-only by design (see [Architecture](#typewriter-is-a-view-layer-effect)) — switching conversations or restarting the app shows persisted text immediately, with no replay.

Code: `lib/chat/widgets/{chat_composer,typewriter_text,chat_bubble}.dart`; coordinated via `AppBloc.streamingMessageId` + `AppStreamingCompleted`.

### Bonus #2 — Rename and delete conversations

Long-pressing a conversation row inside the drawer opens a floating context menu anchored to the row, with **Rename**, **Move to folder…**, and **Delete**. Conversations are auto-titled from the first user message (~40 chars) and can be renamed at any time. Deletion requires an explicit confirmation dialog.

**Rationale.** Once history grows beyond a handful of chats, the inability to rename or delete them becomes immediately painful. This is the most-felt absence in any chat app with persistent history.

**Tradeoffs.**

- **Long-press vs. swipe gestures.** Swipe is more efficient (one motion, no menu), but it requires per-row dismissibles, undo affordances, and a much larger test surface. A long-press context menu reuses a single component across conversations and folders, is a familiar mobile pattern, and is simpler to test. I accepted slightly worse efficiency for materially simpler code.
- **Floating context menu vs. modal bottom sheet.** A bottom sheet is a common Material pattern but it visually disconnects the menu from the row the user pressed. A small floating panel anchored to the row keeps the action options visually tethered to their target. The "Move to folder…" sub-action cascades from the same context menu, so the entire long-press flow stays in one consistent visual register.
- **No undo / trash bin.** A confirmation dialog is sufficient given the low blast radius of a single conversation; a trash bin would have added meaningful state and UI for a demo-scale app.

Code: long-press via `MenuAnchor` in `lib/conversations/widgets/conversation_tile.dart`; rename via `ConversationsCubit.rename`; delete via `AppConversationDeleted` on `AppBloc`; dialogs in `lib/conversations/widgets/{rename,delete}_conversation_dialog.dart`.

### Bonus #3 — Folders, folder CRUD, and conversation move

Inside the drawer, content becomes a two-level view: user-created folders ("Books", "Lifestyle", …) on top, with an "Uncategorized" bucket below for conversations that haven't been filed. A `+` action in the drawer header creates a new folder. Long-pressing a folder opens a floating context menu anchored to the row, with **Rename** and **Delete**. The conversation long-press menu includes **Move to folder…**, which cascades into a floating sub-menu listing every folder, "Uncategorized", and "New folder…".

I treat folders, folder CRUD, and conversation move as a single cohesive bonus feature: without folder rename/delete, folders would be unmanageable; without "move", they would be useless.

**Rationale.** Conversation history scales poorly without organization. A flat list of dozens of chats forces the user to scan every time. Folders are the simplest organizational primitive that makes history usable at scale.

**Tradeoffs.**

- **Folder nesting was rejected.** Nesting adds breadcrumbs, recursive UI, harder data modeling, and trickier delete semantics. A flat hierarchy is enough for a chat app of this scope.
- **Cascade delete vs. auto-move to Uncategorized.** Deleting a folder permanently deletes every conversation inside it, rather than moving them to Uncategorized. This is more destructive but produces a cleaner mental model — "delete folder" really means delete. I mitigate the risk with a confirmation dialog that names the conversation count, e.g. _"Delete 'Books'? This will permanently delete 12 conversations."_
- **Move-to-folder includes the current folder.** The submenu lists every folder without filtering out the conversation's current one. Picking the current folder is short-circuited at the call site — no repository round-trip. Filtering it out would have meant a context-aware menu component for marginal UX gain.

Code: two-section drawer (`lib/conversations/view/conversations_drawer.dart`) with folders rendered via `lib/conversations/widgets/folder_tile.dart`; CRUD via `ConversationsCubit.{createFolder,renameFolder,moveConversation,moveConversationToNewFolder}`; folder delete (cascading) via `AppFolderDeleted` on `AppBloc`; dialogs in `lib/conversations/widgets/{create,rename,delete}_folder_dialog.dart`.

---

## Running Tests 🧪

The project maintains **100% test coverage** across the app and every workspace package. Tests use `flutter_test`, `bloc_test`, and `mocktail`.

```sh
# Run the full suite (app + every workspace package) with coverage and randomized ordering.
# The --recursive flag walks the directory tree and runs every package's test suite in one go.
$ very_good test --coverage --min-coverage 100 --test-randomize-ordering-seed random --recursive

# A single test file or single test
$ very_good test test/path/to/file_test.dart
$ very_good test test/path/to/file_test.dart --name "describes what the test does"
```

To view the generated coverage report you can use [lcov](https://github.com/linux-test-project/lcov):

```sh
# Generate Coverage Report
$ genhtml coverage/lcov.info -o coverage/

# Open Coverage Report
$ open coverage/index.html
```

---

## Bloc Lints 🔍

This project uses the [bloc_lint](https://pub.dev/packages/bloc_lint) package to enforce best practices using [bloc](https://pub.dev/packages/bloc).

To validate linter errors, run:

```bash
$ fvm dart run bloc_tools:bloc lint .
```

You can also validate with VSCode-based IDEs using the [official bloc extension](https://marketplace.visualstudio.com/items?itemName=FelixAngelov.bloc).

To learn more, visit https://bloclibrary.dev/lint/

---

## Working with Translations 🌐

This project follows the [official internationalization guide for Flutter][internationalization_link] using [ARB files][arb_documentation_link] for translations.

### Adding Strings

1. To add a new localizable string, open the `app_en.arb` file at `lib/l10n/arb/app_en.arb` and add a new key/value pair with the relevant description (optional):

```arb
{
    "@@locale": "en",
    "counterAppBarTitle": "Counter",
    "@counterAppBarTitle": {
        "description": "Text shown in the AppBar of the Counter Page"
    },
    "helloWorld": "Hello World",
    "@helloWorld": {
        "description": "Hello World greeting."
    }
}
```

2. Use the new string:

```dart
import 'package:ask_ai_app/l10n/l10n.dart';

@override
Widget build(BuildContext context) {
  final l10n = context.l10n;
  return Text(l10n.helloWorld);
}
```

### Adding Supported Locales

Update the `CFBundleLocalizations` array in the `Info.plist` at `ios/Runner/Info.plist` to include the new locale.

```xml
    ...

    <key>CFBundleLocalizations</key>
	<array>
		<string>en</string>
		<string>es</string>
	</array>

    ...
```

### Adding Translations

1. For each supported locale, add a new ARB file in `lib/l10n/arb`:

```
├── l10n
│   ├── arb
│   │   ├── app_en.arb
│   │   └── app_es.arb
```

2. Add the translated strings to the new `.arb` file:

`app_es.arb`

```arb
{
    "@@locale": "es",
    "counterAppBarTitle": "Contador",
    "@counterAppBarTitle": {
        "description": "Texto mostrado en la AppBar de la página del contador"
    },
    "helloWorld": "Hola Mundo",
    "@helloWorld": {
        "description": "Saludo Hola Mundo."
    }
}
```

### Generating Translations

To use the latest translations, regenerate them:

```sh
$ fvm flutter gen-l10n --arb-dir="lib/l10n/arb"
```

Alternatively, run `fvm flutter run` and code generation will take place automatically.

[coverage_badge]: coverage_badge.svg
[internationalization_link]: https://docs.flutter.dev/ui/internationalization
[arb_documentation_link]: https://github.com/google/app-resource-bundle
[license_badge]: https://img.shields.io/badge/license-MIT-blue.svg
[license_link]: https://opensource.org/licenses/MIT
[very_good_analysis_badge]: https://img.shields.io/badge/style-very_good_analysis-B22C89.svg
[very_good_analysis_link]: https://pub.dev/packages/very_good_analysis
[fvm_link]: https://fvm.app
[drift_link]: https://pub.dev/packages/drift
