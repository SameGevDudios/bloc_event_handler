# Bloc Error Handler

A Flutter package that provides a clean, unified, and highly customizable way to handle exceptions across multiple BLoCs. Built specifically to work seamlessly with `flutter_bloc` and `dio`.

## Features

* **Unified Error Handling:** Centralize your error mapping logic using the `BlocErrorHandler` mixin.
* **Reduced Boilerplate:** Say goodbye to repetitive `try/catch` blocks in every event handler by using the `runSafe` method.
* **Automatic Dio Categorization:** Automatically categorizes `DioException` into distinct groups: Connection errors, Unauthorized (401), Client errors (4xx), and Server errors (5xx).
* **Data Parsing Safety:** Automatically catches and maps `FormatException` and `TypeError`.
* **Local Overrides:** Need a specific error state for a single API call? Easily override the global BLoC configuration directly at the call site.
* **Integrated Logging Hook:** Includes an `onErrorLogged` hook to easily forward caught exceptions to Crashlytics, Sentry, or your custom logger.

## Getting started

To use this package, you need to have `flutter_bloc` and `dio` installed in your project.

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_bloc: ^9.1.1
  dio: ^5.11.0
```

## Usage

Here is a complete example of how to integrate `BlocErrorHandler` into your BLoC.

**1. Add the mixin to your Bloc and configure the mapper:**

```dart
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:your_package_name/bloc_error_handler.dart';

class ExampleBloc extends Bloc<ExampleEvent, ExampleState>
    with BlocErrorHandler<ExampleEvent, ExampleState> {

  ExampleBloc() : super(const ExampleState$Initial()) {
    on<FetchDataEvent>(_onFetchData);
  }

  // 2. Override the errorStateConfig to map error categories to your states
  @override
  BlocErrorMapper<ExampleState> get errorStateConfig => BlocErrorMapper(
    // Define specific UI states for particular network issues
    connection: (message) => ExampleState$NetworkError(message),
    unauthorized: (message) => ExampleState$Logout(message),
    
    // Other categories may remain null if unneeded.
    // If they occur, they will fall back to `defaultError`.

    defaultError: (error, stack) => ExampleState$CommonError('Something went wrong: $error'),
  );

  // Optional: Send logs to Sentry, Crashlytics, etc.
  @override
  void onErrorLogged(Object error, StackTrace stackTrace) {
    // Sentry.captureException(error, stackTrace: stackTrace);
  }

  // 3. Use `runSafe` in your event handlers
  Future<void> _onFetchData(
    FetchDataEvent event,
    Emitter<ExampleState> emit,
  ) => runSafe(emit, () async {
    
    emit(const ExampleState$Loading());
    
    // ... your logic here ...
    
    emit(const ExampleState$Success());

  },
  // Optional: Intercept a specific error directly at the call site
  overrideError: (error, stack) {
    if (error is CustomSilentException) {
      return const ExampleState$SilentError();
    }
    
    return null; // Let the default mapper handle everything else
  });
}

```

## Additional information

* **Customization:** The package adheres to the Open-Closed Principle (OCP). You only need to provide state mappings for the errors you actually care about in a specific BLoC. Anything unmapped falls back to `defaultError`.
* **Contributions:** Issues and pull requests are welcome! If you find a bug or want to suggest a new feature, please open an issue in the repository.
* **Response Time:** The maintainers usually respond to issues within 48 hours.