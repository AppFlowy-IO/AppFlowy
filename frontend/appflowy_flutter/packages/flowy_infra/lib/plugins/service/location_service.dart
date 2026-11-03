import 'dart:io';

class PluginLocationService {
  const PluginLocationService({
    required Future<Directory> fallback,
    List<Future<Directory>>? additionalLocations,
  })  : _fallback = fallback,
        _additionalLocations = additionalLocations ?? const [];

  final Future<Directory> _fallback;
  final List<Future<Directory>> _additionalLocations;

  Future<Directory> get fallback async => _fallback;

  Future<Directory> get location async => fallback;

  /// Returns the primary and all additional scan locations.
  Future<List<Directory>> get allLocations async {
    final primary = await fallback;
    final extras = await Future.wait(_additionalLocations);
    return [primary, ...extras];
  }
}
