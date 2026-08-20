import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'bloc_error_mapper.dart';

/// A component that unifies state emission across multiple event handlers
/// for various exceptions defined in [bloc_error_mapper.dart].
///
/// ## HOW TO USE:
/// 1. Add `with BlocErrorHandler` to your Bloc
/// 2. Override the `errorStateConfig` getter
/// 3. Specify only the required states
/// 4. Use `runSafe` inside your `on<Event>` handlers instead of `try catch`
///
/// ```
/// class ExampleBloc extends Bloc<ExampleEvent, ExampleState>
///     with BlocErrorHandler<ExampleEvent, ExampleState> {
///
///   ExampleBloc() : super(const ExampleState$Initial()) {
///     on<FetchDataEvent>(_onFetchData);
///   }
///
///   @override
///   BlocErrorMapper<ExampleState> get errorStateConfig => BlocErrorMapper(
///     // Define specific UI states for particular issues
///     connection: (message) => ExampleState$NetworkError(message),
///     unauthorized: (message) => ExampleState$Logout(message),
///
///         // Other categories may remain null if unneeded.
///         // If they occur, they will fall back to `defaultError`.
///
///     defaultError: (error, stack) => ExampleState$CommonError('Something went wrong: $error'),
///   );
///
///   @override
///   void onErrorLogged(Object error, StackTrace stackTrace) {
///     // Sentry.captureException(error, stackTrace: stackTrace);
///   }
///
///   Future<void> _onFetchData(
///     FetchDataEvent event,
///     Emitter<ExampleState> emit,
///   ) => runSafe(emit, () async {
///
///     emit(const ExampleState$Loading());
///     // ... your logic here ...
///     emit(const ExampleState$Success());
///
///   },
///   // Optional: You can intercept a specific error directly at the call site,
///   // overriding the global errorStateConfig.
///   overrideError: (error, stack) {
///     if (error is CustomSilentException) return const ExampleState$SilentError();

///     return null;
///   });
/// }
/// ```
mixin BlocErrorHandler<Event, State> on Bloc<Event, State> {
  /// Single point of error state configuration for the current BLoC.
  BlocErrorMapper<State> get errorStateConfig;

  /// Optional hook for sending logs to Crashlytics, Sentry, etc.
  void onErrorLogged(Object error, StackTrace stackTrace) {}

  /// Executes [action], automatically catching exceptions and emitting the mapped state.
  ///
  /// [overrideError] allows targeted state overrides for a specific
  /// call (e.g., to display a custom error on a specific screen).
  Future<void> runSafe(
    Emitter<State> emit,
    Future<void> Function() action, {
    State? Function(Object error, StackTrace stackTrace)? overrideError,
  }) async {
    try {
      await action();
    } catch (error, stackTrace) {
      onErrorLogged(error, stackTrace);

      if (overrideError != null) {
        final customState = overrideError(error, stackTrace);
        if (customState != null) {
          emit(customState);

          return;
        }
      }

      final mappedState = _mapErrorToState(error);

      emit(mappedState ?? errorStateConfig.defaultError(error, stackTrace));
    }
  }

  State? _mapErrorToState(Object error) {
    if (error is DioException) {
      final serverMessage = _extractMessage(error.response?.data);

      const networkErrorTypes = {
        DioExceptionType.connectionTimeout,
        DioExceptionType.receiveTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.connectionError,
      };

      if (networkErrorTypes.contains(error.type)) {
        return errorStateConfig.connection?.call(serverMessage ?? 'Connection error');
      }

      final statusCode = error.response?.statusCode ?? 0;

      if (statusCode == 401) {
        return errorStateConfig.unauthorized?.call(serverMessage ?? 'Session expired');
      }
      if (statusCode >= 400 && statusCode < 500) {
        return errorStateConfig.client?.call(serverMessage ?? 'Bad request', statusCode);
      }
      if (statusCode >= 500 && statusCode < 600) {
        return errorStateConfig.server?.call(serverMessage ?? 'Server error', statusCode);
      }
    }

    if (error is FormatException || error is TypeError) {
      return errorStateConfig.format?.call('Data parsing error');
    }

    return null;
  }

  String? _extractMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data['message'] as String? ?? data['error'] as String? ?? data['detail'] as String?;
    }
    
    return null;
  }
}
