abstract class FlowyResult<S, F extends Object> {
  const FlowyResult();

  factory FlowyResult.success(S s) => FlowySuccess(s);

  factory FlowyResult.failure(F f) => FlowyFailure(f);

  T fold<T>(T Function(S s) onSuccess, T Function(F f) onFailure);

  FlowyResult<T, F> map<T>(T Function(S success) fn);
  FlowyResult<S, T> mapError<T extends Object>(T Function(F failure) fn);

  bool isSuccess();
  bool isFailure();

  S? toNullable();

  void onSuccess(void Function(S s) onSuccess);
  void onFailure(void Function(F f) onFailure);

  S getOrElse(S Function(F failure) onFailure);
  S getOrThrow();
}

class FlowySuccess<S, F extends Object> implements FlowyResult<S, F> {
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
  FlowyResult<S, T> mapError<T extends Object>(T Function(F error) fn) {
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

  @override
  void onSuccess(void Function(S success) onSuccess) {
    onSuccess(_value);
  }

  @override
  void onFailure(void Function(F failure) onFailure) {}

  @override
  getOrElse(S Function(F failure) onFailure) {
    return _value;
  }

  @override
  getOrThrow() {
    return _value;
  }
}

class FlowyFailure<S, F extends Object> implements FlowyResult<S, F> {
  final F _value;

  FlowyFailure(this._value);

  F get error => _value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FlowyFailure &&
          runtimeType == other.runtimeType &&
          _value == other._value;

  @override
  int get hashCode => _value.hashCode;

  @override
  String toString() => 'Failure(error: $_value)';

  @override
  T fold<T>(T Function(S s) onSuccess, T Function(F e) onFailure) =>
      onFailure(_value);

  @override
  map<T>(T Function(S success) fn) {
    return FlowyFailure(_value);
  }

  @override
  FlowyResult<S, T> mapError<T extends Object>(T Function(F error) fn) {
    return FlowyFailure(fn(_value));
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

  @override
  void onSuccess(void Function(S success) onSuccess) {}

  @override
  void onFailure(void Function(F failure) onFailure) {
    onFailure(_value);
  }

  @override
  getOrElse(S Function(F failure) onFailure) {
    return onFailure(_value);
  }

  @override
  S getOrThrow() {
    throw _value;
  }
}
