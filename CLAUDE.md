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

### Implementation Status

| Feature | Status | Code / Notes |
| --- | --- | --- |
| Required #1 — Real-time chat | Done | `lib/chat/`, `packages/chat_client/{chat_client,web_socket_chat_client}`, `packages/chat_repository` |
| Required #2 — Conversation history | Done | drift-backed persistence (`packages/conversations_client/{conversations_client,drift_conversations_client}`, `packages/conversations_repository`), `AppBloc` orchestration (`lib/app/`), per-conversation `ChatBloc` (`lib/chat/`), conversations drawer (`lib/conversations/`). |
| Bonus #1 — Typewriter streaming + in-flight send button | Done | `lib/chat/widgets/{chat_composer,typewriter_text,chat_bubble}.dart`; coordinated via `ChatState.streamingMessageId` + `ChatStreamingCompleted` |
| Bonus #2 — Rename / delete conversations | Not started | Depends on Required #2 |
| Bonus #3 — Folders + folder CRUD + move | Not started | Depends on Required #2 |

### Settled Design Choices (do not relitigate)

- **Persistence backend:** drift (over hydrated_bloc/hive). Reactive `watch()` + native cascade deletes for the bonus features.
- **Per-conversation WebSocket sockets** (Design A) lifted to app-level via the registry, not one shared socket with FIFO routing. Each conversation's echoes return on its own socket — routing is structural.
- **Empty conversations are not persisted** until first send; `activeConversationId == null` represents the "new chat in progress" state.
- **Auto-title:** trim and take first 40 chars (with `…` suffix when longer) of the user's first message in a fresh conversation. Implemented as `AppBloc.autoTitle`.
- **Last-active resume:** `app_metadata` row keyed by `lastActiveConversationKey`. Loaded on `AppStarted`, persisted on every `AppConversationActivated` / `AppNewConversationRequested`.
- **Typewriter on background-arrived echoes:** plain text on return — no replay. Achieved by AppBloc only setting `streamingMessageId` when the echo's `conversationId == activeConversationId`. Switching conversations clears `streamingMessageId`.

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

### Test File Conventions

- **Mirror the source tree 1:1.** Every file under `lib/` (or any package's `lib/`) gets exactly one matching `*_test.dart` under `test/`. Do **not** stuff tests for `chat_state.dart` and `chat_event.dart` into `chat_bloc_test.dart` — each gets its own file.
- **Hoist a `buildBloc` / `buildCubit` / `pumpFoo` helper** at the top of `main()` instead of repeating constructor calls in every test. Reduces noise and makes the system-under-test obvious from one place.
- **Reference objects in `group` and `test` names.** Use the type literal in `group(MyBloc, () { ... })` and reference symbols inside descriptions with `$MyEvent` interpolation (e.g. `'dispatches $ChatMessageSubmitted on tap'`) rather than raw strings — IDEs can then jump from the test name to the symbol, and renames flow through.

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
- `lib/chat/` is the canonical feature-folder layout: `bloc/` + `model/` + `view/` + `widgets/` plus a barrel `chat.dart` that re-exports the public surface. Follow the same pattern for new features (substitute `cubit/` for `bloc/` if a cubit is the better fit).
- Tests mirror `lib/` under `test/`. Shared widget-test helpers (pump helpers, mock setup) live in `test/helpers/`.

### Chat Feature Internals

These are the seams of the multi-conversation chat surface as it ships today.

- **Page composition.** `ChatPage` (`lib/chat/view/chat_page.dart`) provides a page-scoped `ConversationsCubit` (drawer + AppBar title share it). `ChatView` reads `AppBloc.activeConversationId` and renders either an empty-state body (chat empty-state above a callback-only composer) or `_ActiveChatBody`, which is keyed by `ValueKey(activeConversationId)` so the bloc subtree is rebuilt on every conversation switch.
- **ChatBloc lifecycle.** `ChatBloc` (`lib/chat/bloc/chat_bloc.dart`) takes `conversationId`, `ConversationsRepository`, and a `ChatRepositoryProvider` (`Future<ChatRepository> Function(String)` — supplied as `appBloc.obtainChatRepository`). It subscribes to `watchMessages(conversationId)` in its constructor and emits `ChatMessagesUpdated` on every drift snapshot. `close()` cancels the subscription. There is no explicit connect/disconnect on the bloc — the `ChatRepositoryRegistry` owns connection lifecycle.
- **Message store.** `ChatState.messages` mirrors the latest snapshot from `watchMessages` (oldest → newest). `Message` carries `id`, `conversationId`, `role`, `text`, `sentAt`. `awaitingResponse` is derived structurally as `messages.isNotEmpty && messages.last.role == MessageRole.user`.
- **Send paths.** Two paths converge at the same drift writes:
  - **First send (`activeConversationId == null`).** The empty-state composer fires `AppFirstMessageSubmitted(text)` to `AppBloc`, which runs `autoTitle` → `createConversation` → `appendMessage` (user) → activate id (and persist last-active metadata) → `obtainChatRepository` → `send`. Failures map to `AppTransientError.{persistenceFailed,connectionFailed,messageTooLarge,sendFailed}`.
  - **Subsequent sends.** `_ActiveChatComposer` fires `ChatMessageSubmitted(text)` to the per-conversation `ChatBloc`, which trims, no-ops on blank or while awaiting, `appendMessage`s the user message (persistenceFailed on throw), clears any pending transient error, obtains the repository (connectionFailed on `ChatClientException`), and calls `send` (messageTooLarge / sendFailed on the respective subtypes).
- **Echo path.** Assistant echoes are persisted by `AppBloc._onEchoReceived` (not the chat bloc) so a background-arrived echo always lands on the right conversation regardless of which surface is mounted. The view sees them via the same `watchMessages` stream.
- **Streaming hooks.** `streamingMessageId` lives on `AppBloc.state`; only set when the echo's `conversationId == activeConversationId` (no replay on background-arrived messages). `_ChatMessagesList` mirrors it via a `BlocSelector<AppBloc, AppState, String?>` and passes `streaming: m.id == streamingId` into each `ChatBubble`. The typewriter completion fires `AppStreamingCompleted(id)` back at `AppBloc`. `_ActiveChatComposer` combines `streamingMessageId != null` with `ChatBloc.awaitingResponse` to compute the composer's `inFlight` flag.
- **Composer.** `ChatComposer` is bloc-agnostic — it accepts `onSubmit(String)` + `inFlight: bool`. Send tap and the keyboard send action both go through `_sendMessage`, which gates on `!inFlight && trimmed.isNotEmpty`.
- **Transient errors.** Both `ChatBloc` and `AppBloc` carry a `transientError`. `ChatView` hosts the `AppBloc` `BlocListener`; `_ActiveChatBody` hosts the `ChatBloc` one. Each fires its corresponding `*TransientErrorCleared` event after surfacing the snackbar. Error → string mapping lives at the bottom of `chat_page.dart` (`_appErrorMessage` / `_chatErrorMessage`).
- **Drawer wiring.** `Scaffold.drawer` wraps `ConversationsDrawerView` in a `Builder` so `Scaffold.of(context).closeDrawer()` resolves. Tile taps dispatch `AppConversationActivated(id)`; the header CTA dispatches `AppNewConversationRequested`. The drawer reads `activeConversationId` for selected styling.

### Packages

The workspace splits domain code into local packages under `packages/`. Each is its own pub package with its own tests and 100% coverage threshold.

| Package | Purpose |
| --- | --- |
| `packages/app_ui` | Design system: spacing, radii, typography, theme tokens, and **reusable cross-feature widgets**. Re-exports `flutter/material.dart` so consumers import a single barrel (`package:app_ui/app_ui.dart`). |
| `packages/chat_client/chat_client` | Transport-agnostic `[ChatClient]` interface, domain models, and the `[ChatClientException]` hierarchy. Has no transport dependency — pure contract. |
| `packages/chat_client/web_socket_chat_client` | WebSocket-backed `[ChatClient]` implementation. Wraps `web_socket_channel` and maps transport errors onto the `[ChatClientException]` hierarchy per the error-handling convention above. |
| `packages/chat_repository` | Bridges a `[ChatClient]` to feature blocs/cubits. App-layer code (blocs, cubits, views) depends on this — never on a `*_client` package directly. |

#### Where a new widget belongs

1. **Reusable across features** (e.g. an `AppButton` variant, a generic empty-state, a chat bubble shared by multiple screens) → add it to `packages/app_ui` and export it from `app_ui.dart`. Any feature can then pull it via `package:app_ui/app_ui.dart`.
2. **Used only inside one feature** → create `lib/<feature>/widgets/` and put the widget there, exporting through the feature barrel.
3. **Trivial and single-use inside the view** → inline it in the view file (e.g. `lib/<feature>/view/<feature>_page.dart`) rather than spinning up a `widgets/` directory for one private widget.
