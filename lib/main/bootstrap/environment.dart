/// Compile-time configuration sourced from `env-<flavor>.json` via
/// `--dart-define-from-file`.
final class Environment {
  const Environment._();

  /// WebSocket echo endpoint used by the chat client.
  static const webSocketEchoEndpoint = String.fromEnvironment('WS_ENDPOINT');
}
