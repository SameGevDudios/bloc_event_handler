/// Configuration for mapping error categories to BLoC states.
/// the error falls back to the mandatory [defaultError].
class BlocErrorMapper<State> {
  /// Network errors: timeouts, no internet connection, connection drops.
  final State Function(String message)? connection;

  /// Authorization error (HTTP 401).
  final State Function(String message)? unauthorized;

  /// Client input errors (HTTP 400-499, excluding 401).
  final State Function(String message, int statusCode)? client;

  /// Internal server errors (HTTP 500-599).
  final State Function(String message, int statusCode)? server;

  /// Parsing/typing errors (FormatException, TypeError).
  final State Function(String message)? format;

  /// Mandatory fallback for all other unknown or unhandled errors.
  final State Function(Object error, StackTrace stackTrace) defaultError;

  const BlocErrorMapper({
    this.connection,
    this.unauthorized,
    this.client,
    this.server,
    this.format,
    required this.defaultError,
  });
}
