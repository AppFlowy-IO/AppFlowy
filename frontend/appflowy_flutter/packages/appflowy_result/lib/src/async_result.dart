import 'package:appflowy_result/appflowy_result.dart';

typedef FlowyAsyncResult<S, F extends Object> = Future<FlowyResult<S, F>>;

extension FlowyAsyncResultExtension<S, F extends Object>
    on FlowyAsyncResult<S, F> {
  Future<S> getOrElse(S Function(F f) onFailure) {
    return then((result) => result.getOrElse(onFailure));
  }

  Future<S?> toNullable() {
    return then((result) => result.toNullable());
  }

  Future<S> getOrThrow() {
    return then((result) => result.getOrThrow());
  }

  Future<W> fold<W>(
    W Function(S s) onSuccess,
    W Function(F f) onFailure,
  ) {
    return then<W>((result) => result.fold(onSuccess, onFailure));
  }

  Future<bool> isError() {
    return then((result) => result.isFailure);
  }

  Future<bool> isSuccess() {
    return then((result) => result.isSuccess);
  }

  FlowyAsyncResult<S, F> onFailure(void Function(F failure) onFailure) {
    return then((result) => result..onFailure(onFailure));
  }
}
