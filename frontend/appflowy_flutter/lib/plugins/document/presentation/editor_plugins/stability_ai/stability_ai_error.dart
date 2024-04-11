class StabilityAIRequestError {
  StabilityAIRequestError(this.message);

  final String message;

  @override
  String toString() {
    return 'StabilityAIRequestError{message: $message}';
  }
}
