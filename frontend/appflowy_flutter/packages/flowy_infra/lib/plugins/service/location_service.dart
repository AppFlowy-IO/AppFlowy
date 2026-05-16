import 'dart:io';

class PluginLocationService {
  const PluginLocationService({
    required Future<Directory> fallback,
  }) : _fallback = fallback;

  final Future<Directory> _fallback;

  Future<Directory> get fallback async => _fallback;

  Future<Directory> get location async => fallback;
}
