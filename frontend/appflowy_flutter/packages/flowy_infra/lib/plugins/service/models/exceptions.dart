class PluginRemovalException implements Exception {
  final String message;

  PluginRemovalException(this.message);
}

class PluginCompilationException implements Exception {
  final String message;

  PluginCompilationException(this.message);
}

class PluginLoadingException implements Exception {
  final String message;

  PluginLoadingException(this.message);
}
