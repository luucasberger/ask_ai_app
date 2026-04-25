# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## The Challenge

Build **AskAI**, a minimal Flutter chat app that simulates a conversation with an AI assistant. Messages are sent over a WebSocket and the server's echoed response is rendered as if it were an AI reply. The brief is intentionally open-ended — assumptions, constraints, and product decisions are expected to be made and justified.

### WebSocket Endpoint

- Primary: `wss://echo.websocket.org`
- Backup: `wss://echo-websocket.fly.dev`
- No auth. 64KB message limit. Connections drop after 10 min of inactivity.

### Required Features

1. **Real-time chat** — user sends text, the echoed response appears as an assistant reply in a chat UI.
2. **Conversation history** — past conversations are listed and resumable, messages persist across app restarts, and a new conversation can be started.

### Bonus Features

Three bonus features ship on top of the required ones, after the required features land. Each is documented in `README.md` with rationale and tradeoffs.

1. **Typewriter streaming + in-progress send button.** The echoed assistant response is revealed character-by-character (sensible default, e.g. ~30ms/char) rather than appearing all at once. Streaming always plays out in full — there is no fast-forward / skip interaction. While a response is in flight, the composer's send button is replaced by an animated in-progress indicator that persists until the stream completes. Persisted messages store the full final text only — streaming is a view-layer effect.

2. **Rename and delete conversations.** Long-pressing a conversation row inside the drawer opens a floating context menu anchored to the row, with **Rename**, **Move to folder…**, and **Delete**. Default conversation title is auto-generated from the first user message (~40 chars). Delete shows a confirmation dialog (no count line) before removing the conversation. Tapping **Move to folder…** opens a cascading floating sub-menu (anchored from the parent context menu) listing existing folders, "Uncategorized", and "New folder…"; the sub-menu scrolls if there are many folders.

3. **Folders + folder CRUD + move conversations.** Inside the drawer, content becomes a two-level view: user-created folders on top, an "Uncategorized" bucket below (no conversation is ever orphaned). Folders cannot be nested. A `+` action in the drawer creates a new folder. Long-pressing a folder opens a floating context menu anchored to the row, with **Rename** and **Delete** — deleting a folder cascades and permanently deletes every conversation inside it. The folder delete confirmation must name the conversation count, e.g. *"Delete 'Books'? This will permanently delete 12 conversations."*

Interaction model across both conversations and folders: **long-press → floating context menu** (anchored to the long-pressed row, not a modal bottom sheet). No swipe gestures. Implement with `showMenu` / `MenuAnchor` on Material and `CupertinoContextMenu` on iOS — pick whichever single cross-platform abstraction reads cleanest in this codebase.

## Tech Stack & Constraints

- **Flutter version is pinned via fvm** (`.fvmrc` → 3.41.7). Prefix Flutter/Dart commands with `fvm` so the pinned SDK is used.
- **Platforms:** iOS and Android only. macOS, Windows, and web support have been removed on purpose — do not re-add platform folders or platform-specific code for them.
- **State management:** `bloc` / `flutter_bloc`. The project enforces `bloc_lint` recommended rules.
- **Lints:** `very_good_analysis` + `bloc_lint` (see `analysis_options.yaml`). `public_member_api_docs` is disabled; `lib/l10n/gen/*` is excluded.
- **Localization:** ARB-based (`lib/l10n/arb/`), generated into `lib/l10n/gen/` via `flutter gen-l10n`. User-facing strings must go through `context.l10n`.
- **Testing:** `flutter_test`, `bloc_test`, `mocktail`. The project maintains **100% coverage** — every new line of production code must be covered by a test, and coverage must not regress.
- **Always use `very_good_cli`** in place of raw `flutter`/`dart` equivalents whenever an equivalent exists (tests, coverage, project creation, recursive `pub get`, license checks). Invoke the **`very-good-cli` skill** for these operations rather than handcrafting the commands.

### Widget Test Pump Helper: `pumpApp`

Widget tests **must never call `tester.pumpWidget` directly** when a `pumpApp` extension exists for that test directory (see `test/helpers/pump_app.dart`). Always go through `pumpApp` so the widget renders under the same `MaterialApp` configuration the production app uses (theme, localization delegates, supported locales). New shared scaffolding (`BlocProvider`s, repositories, etc.) belongs in `pumpApp` so every test picks it up automatically rather than re-implementing the wiring per-test.

### Test-Only Lint Exception: `const`

`test/analysis_options.yaml` disables `prefer_const_constructors` on purpose. Reason: `const` widget instances in tests can cause flaky tests (widget identity reuse across pumps, cached references, etc.), and the same canonicalization can cause confusing `same()` / identity surprises with value types. Rule of thumb:

- **Never** add `const` inside test files, even when the analyzer would normally prompt for it — the prompt is silenced for exactly this reason.
- **Do** add `const` only when the analyzer still fires a lint or compile error (e.g. when a value must be const for the call site to type-check). Run `fvm dart analyze` to confirm.

### Doc Reference Convention

Use square-bracket dartdoc references (`[ClassName]`, `[ClassName.member]`) when documenting public APIs in any package — never plain backticks for type names. If the type isn't already in scope, import the package barrel (`package:chat_client/chat_client.dart`) so the reference resolves.

### Error Handling Convention (Client Implementations)

Concrete `*_client` implementations wrap every public method in a `try` block. Specific exceptions are mapped on `on TypeException` clauses; the broad `catch (error, stackTrace)` clause uses `Error.throwWithStackTrace(DomainException(error), stackTrace)` to preserve the original stack trace while exposing a domain-typed exception. When a method has **pre-check validations that throw `ChatClientException` subtypes inside the `try` block** (e.g. `MessageTooLargeException`, an explicit "not connected" `SendException`), add `on ChatClientException { rethrow; }` at the top of the catch chain so those domain exceptions propagate without being re-wrapped by the broad catch. Methods whose `try` block cannot throw a `ChatClientException` (e.g. `connect`, `disconnect` — only the transport runs inside) should omit the `on ChatClientException { rethrow; }` clause; it would be redundant.

### Environment Configuration

Each flavor reads compile-time constants from a matching JSON env file at the project root: `env-dev.json` (development), `env-stg.json` (staging), `env-prod.json` (production). Values are accessed via `String.fromEnvironment('KEY')` (typically inside `main_*.dart`) and supplied at build/run time with `--dart-define-from-file=env-<dev|stg|prod>.json`. The current key set:

- `WS_ENDPOINT` — WebSocket URL passed to `WebSocketChatClient` (primary `wss://echo.websocket.org`, backup `wss://echo-websocket.fly.dev`).

## Common Commands

Run via fvm so the pinned Flutter SDK is used:

```sh
# Run the app (three flavors, each with its own entrypoint + env file)
fvm flutter run --flavor development --target lib/main/main_development.dart --dart-define-from-file=env-dev.json
fvm flutter run --flavor staging     --target lib/main/main_staging.dart     --dart-define-from-file=env-stg.json
fvm flutter run --flavor production  --target lib/main/main_production.dart  --dart-define-from-file=env-prod.json

# All tests with coverage + random ordering (enforce 100% coverage)
very_good test --coverage --min-coverage 100 --test-randomize-ordering-seed random

# A single test file / single test (prefer the very-good-cli skill for this)
very_good test test/path/to/file_test.dart
very_good test test/path/to/file_test.dart --name "describes what the test does"

# Bloc lint
fvm dart run bloc_tools:bloc lint .

# Static analysis & formatting
fvm dart analyze
fvm dart format .

# Regenerate localizations (also runs automatically on `flutter run`)
fvm flutter gen-l10n --arb-dir="lib/l10n/arb"
```

## Architecture Notes

- Three flavor entrypoints (`lib/main/main_{development,staging,production}.dart`) all delegate to `bootstrap()` in `lib/main/bootstrap/bootstrap.dart`, which wires up `Bloc.observer` and `FlutterError.onError` before running `App`. Compile-time env values from `env-<flavor>.json` are exposed via `Environment` in `lib/main/bootstrap/environment.dart`. Put cross-flavor setup inside `bootstrap`, not inside individual `main_*.dart` files.
- **Conversation history lives in a left-edge navigation drawer** — same pattern as the ChatGPT and Claude mobile apps. The active chat is the main screen; swiping from the left edge or tapping a menu button slides the drawer in. The "new conversation" action lives inside the drawer header. When folders ship (bonus feature), they occupy the top of the same drawer with the conversation list below them.
- `lib/counter/` is **placeholder scaffolding** from Very Good CLI. It is a reference for feature-folder layout (`feature/cubit` + `feature/view` + barrel file) and should be removed or replaced as real AskAI features land.
- Follow the same feature-folder pattern for new features: `lib/<feature>/{bloc|cubit,view,widgets}` with a barrel `lib/<feature>/<feature>.dart` that re-exports the public surface.
- Tests mirror `lib/` under `test/`. Shared widget-test helpers (pump helpers, mock setup) live in `test/helpers/`.
