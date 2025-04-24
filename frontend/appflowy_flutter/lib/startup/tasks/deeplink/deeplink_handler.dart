import 'dart:async';

import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';

typedef DeepLinkResultHandler = void Function(
  DeepLinkHandler handler,
  FlowyResult<dynamic, FlowyError> result,
);

typedef DeepLinkStateHandler = void Function(
  DeepLinkHandler handler,
  DeepLinkState state,
);

typedef DeepLinkErrorHandler = void Function(
  FlowyError error,
);

abstract class DeepLinkHandler<T> {
  /// Checks if this handler should handle the given URI
  bool canHandle(Uri uri);

  /// Handles the deep link URI

  Future<FlowyResult<T, FlowyError>> handle({
    required Uri uri,
    required DeepLinkStateHandler onStateChange,
  });
}

class DeepLinkHandlerRegistry {
  DeepLinkHandlerRegistry._();
  static final instance = DeepLinkHandlerRegistry._();

  final List<DeepLinkHandler> _handlers = [];

  /// Register a new DeepLink handler
  void register(DeepLinkHandler handler) {
    _handlers.add(handler);
  }

  Future<void> processDeepLink({
    required Uri uri,
    required DeepLinkStateHandler onStateChange,
    required DeepLinkResultHandler onResult,
    required DeepLinkErrorHandler onError,
  }) async {
    Log.info('Processing DeepLink: ${uri.toString()}');

    bool handled = false;

    for (final handler in _handlers) {
      if (handler.canHandle(uri)) {
        Log.info('Handler ${handler.runtimeType} will handle the DeepLink');

        final result = await handler.handle(
          uri: uri,
          onStateChange: onStateChange,
        );

        onResult(handler, result);

        handled = true;
        break;
      }
    }

    if (!handled) {
      Log.error('No handler found for DeepLink: ${uri.toString()}');

      onError(
        FlowyError(msg: 'No handler found for DeepLink: ${uri.toString()}'),
      );
    }
  }
}

class DeepLinkResult<T> {
  DeepLinkResult({
    required this.state,
    this.result,
  });
  final DeepLinkState state;
  final FlowyResult<T, FlowyError>? result;
}

enum DeepLinkState {
  none,
  loading,
  finish,
  error,
}
