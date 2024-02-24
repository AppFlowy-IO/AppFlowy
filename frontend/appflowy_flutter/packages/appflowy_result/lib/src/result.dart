abstract class FlowyResult<S, F> {
  const FlowyResult();

  factory FlowyResult.success(S s) => FlowySuccess(s);

  factory FlowyResult.failure(F e) => FlowyFailure(e);

  T fold<T>(T Function(S s) onSuccess, T Function(F e) onFailure);

  FlowyResult<T, F> map<T>(T Function(S success) fn);
  FlowyResult<S, T> mapError<T>(T Function(F error) fn);

  bool isSuccess();
  bool isFailure();

  S? toNullable();
}

class FlowySuccess<S, F> implements FlowyResult<S, F> {
  final S _value;

  FlowySuccess(this._value);

  S get value => _value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FlowySuccess &&
          runtimeType == other.runtimeType &&
          _value == other._value;

  @override
  int get hashCode => _value.hashCode;

  @override
  String toString() => 'Success(value: $_value)';

  @override
  T fold<T>(T Function(S s) onSuccess, T Function(F e) onFailure) =>
      onSuccess(_value);

  @override
  map<T>(T Function(S success) fn) {
    return FlowySuccess(fn(_value));
  }

  @override
  FlowyResult<S, T> mapError<T>(T Function(F error) fn) {
    return FlowySuccess(_value);
  }

  @override
  bool isSuccess() {
    return true;
  }

  @override
  bool isFailure() {
    return false;
  }

  @override
  S? toNullable() {
    return _value;
  }
}

class FlowyFailure<S, F> implements FlowyResult<S, F> {
  final F _error;

  FlowyFailure(this._error);

  F get error => _error;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FlowyFailure &&
          runtimeType == other.runtimeType &&
          _error == other._error;

  @override
  int get hashCode => _error.hashCode;

  @override
  String toString() => 'Failure(error: $_error)';

  @override
  T fold<T>(T Function(S s) onSuccess, T Function(F e) onFailure) =>
      onFailure(_error);

  @override
  map<T>(T Function(S success) fn) {
    return FlowyFailure(_error);
  }

  @override
  FlowyResult<S, T> mapError<T>(T Function(F error) fn) {
    return FlowyFailure(fn(_error));
  }

  @override
  bool isSuccess() {
    return false;
  }

  @override
  bool isFailure() {
    return true;
  }

  @override
  S? toNullable() {
    return null;
  }
}
