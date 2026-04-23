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

Up to 3 additional features of our choosing may be added on top of the required ones. **These are not yet defined** — the required features ship first, then bonus features are decided. Each bonus feature should later be documented in `README.md` with the rationale and tradeoffs considered.

## Tech Stack & Constraints

- **Flutter version is pinned via fvm** (`.fvmrc` → 3.41.7). Prefix Flutter/Dart commands with `fvm` so the pinned SDK is used.
- **Platforms:** iOS and Android only. macOS, Windows, and web support have been removed on purpose — do not re-add platform folders or platform-specific code for them.
- **State management:** `bloc` / `flutter_bloc`. The project enforces `bloc_lint` recommended rules.
- **Lints:** `very_good_analysis` + `bloc_lint` (see `analysis_options.yaml`). `public_member_api_docs` is disabled; `lib/l10n/gen/*` is excluded.
- **Localization:** ARB-based (`lib/l10n/arb/`), generated into `lib/l10n/gen/` via `flutter gen-l10n`. User-facing strings must go through `context.l10n`.
- **Testing:** `flutter_test`, `bloc_test`, `mocktail`. The project maintains **100% coverage** — every new line of production code must be covered by a test, and coverage must not regress.
- **Always use `very_good_cli`** in place of raw `flutter`/`dart` equivalents whenever an equivalent exists (tests, coverage, project creation, recursive `pub get`, license checks). Invoke the **`very-good-cli` skill** for these operations rather than handcrafting the commands.

### Test-Only Lint Exception: `const` on Widgets

`test/analysis_options.yaml` disables `prefer_const_constructors` on purpose. Reason: `const` widget instances in tests can cause flaky tests (widget identity reuse across pumps, cached references, etc.). Rule of thumb:

- **Never** add `const` to widget constructors inside test files, even when the analyzer would normally prompt for it — that prompt is silenced for exactly this reason.
- **Do** add `const` when the analyzer still fires the lint (e.g. on a literal like `<String>['a', 'b']`), since those cases aren't widget-identity hazards.

## Common Commands

Run via fvm so the pinned Flutter SDK is used:

```sh
# Run the app (three flavors, each with its own entrypoint)
fvm flutter run --flavor development --target lib/main_development.dart
fvm flutter run --flavor staging     --target lib/main_staging.dart
fvm flutter run --flavor production  --target lib/main_production.dart

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

- Three flavor entrypoints (`lib/main_{development,staging,production}.dart`) all delegate to `bootstrap()` in `lib/bootstrap.dart`, which wires up `Bloc.observer` and `FlutterError.onError` before running `App`. Put cross-flavor setup inside `bootstrap`, not inside individual `main_*.dart` files.
- `lib/counter/` is **placeholder scaffolding** from Very Good CLI. It is a reference for feature-folder layout (`feature/cubit` + `feature/view` + barrel file) and should be removed or replaced as real AskAI features land.
- Follow the same feature-folder pattern for new features: `lib/<feature>/{bloc|cubit,view,widgets}` with a barrel `lib/<feature>/<feature>.dart` that re-exports the public surface.
- Tests mirror `lib/` under `test/`. Shared widget-test helpers (pump helpers, mock setup) live in `test/helpers/`.
