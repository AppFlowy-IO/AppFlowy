import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flowy_infra/colorscheme/default_colorscheme.dart';
import 'package:flowy_infra/plugins/service/location_service.dart';
import 'package:flowy_infra/plugins/service/plugin_service.dart';
import 'package:flowy_infra/theme.dart';
import 'package:path/path.dart' as p;

/// Creates a minimal `.flowy_plugin` directory with stub theme files.
Directory _createFakePlugin(Directory parent, String name) {
  final pluginDir =
      Directory(p.join(parent.path, '$name.flowy_plugin'))..createSync();

  final colorScheme = const DefaultColorScheme.light().toJson();
  final encoded = jsonEncode(colorScheme);

  File(p.join(pluginDir.path, '$name.light.json'))
    ..createSync()
    ..writeAsStringSync(encoded);
  File(p.join(pluginDir.path, '$name.dark.json'))
    ..createSync()
    ..writeAsStringSync(encoded);

  return pluginDir;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmp;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('appflowy_plugin_test_');
  });

  tearDown(() {
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  group('PluginLocationService', () {
    test('location returns the primary directory', () async {
      final primary = Directory(p.join(tmp.path, 'primary'))..createSync();
      final service = PluginLocationService(fallback: Future.value(primary));

      expect((await service.location).path, equals(primary.path));
    });

    test('allLocations returns primary + additional directories', () async {
      final primary = Directory(p.join(tmp.path, 'primary'))..createSync();
      final extra1 = Directory(p.join(tmp.path, 'extra1'))..createSync();
      final extra2 = Directory(p.join(tmp.path, 'extra2'))..createSync();

      final service = PluginLocationService(
        fallback: Future.value(primary),
        additionalLocations: [Future.value(extra1), Future.value(extra2)],
      );

      final all = await service.allLocations;
      expect(all, hasLength(3));
      expect(all.map((d) => d.path), containsAll([primary.path, extra1.path, extra2.path]));
    });

    test('allLocations returns only primary when no additionalLocations', () async {
      final primary = Directory(p.join(tmp.path, 'primary'))..createSync();
      final service = PluginLocationService(fallback: Future.value(primary));

      final all = await service.allLocations;
      expect(all, hasLength(1));
      expect(all.first.path, equals(primary.path));
    });
  });

  group('FlowyPluginService — multi-location plugin discovery', () {
    test('finds plugins in the primary directory', () async {
      final primary = Directory(p.join(tmp.path, 'primary'))..createSync();
      _createFakePlugin(primary, 'myTheme');

      final service = FlowyPluginService.instance;
      service.setLocation(
        PluginLocationService(fallback: Future.value(primary)),
      );

      final found = await service.plugins;
      expect(found.map((p) => p.name), contains('myTheme'));
    });

    test('finds plugins in the secondary (legacy) directory', () async {
      final primary = Directory(p.join(tmp.path, 'primary'))..createSync();
      final legacy = Directory(p.join(tmp.path, 'legacy'))..createSync();
      _createFakePlugin(legacy, 'legacyTheme');

      final service = FlowyPluginService.instance;
      service.setLocation(
        PluginLocationService(
          fallback: Future.value(primary),
          additionalLocations: [Future.value(legacy)],
        ),
      );

      final found = await service.plugins;
      expect(found.map((p) => p.name), contains('legacyTheme'));
    });

    test('deduplicates plugins with the same name across directories', () async {
      final primary = Directory(p.join(tmp.path, 'primary'))..createSync();
      final legacy = Directory(p.join(tmp.path, 'legacy'))..createSync();

      _createFakePlugin(primary, 'sharedTheme');
      _createFakePlugin(legacy, 'sharedTheme');

      final service = FlowyPluginService.instance;
      service.setLocation(
        PluginLocationService(
          fallback: Future.value(primary),
          additionalLocations: [Future.value(legacy)],
        ),
      );

      final found = await service.plugins;
      final names = found.map((p) => p.name).toList();
      expect(names.where((n) => n == 'sharedTheme'), hasLength(1));
    });

    test('primary location takes precedence over legacy for deduplication', () async {
      final primary = Directory(p.join(tmp.path, 'primary'))..createSync();
      final legacy = Directory(p.join(tmp.path, 'legacy'))..createSync();

      _createFakePlugin(primary, 'shared');
      _createFakePlugin(legacy, 'shared');

      final service = FlowyPluginService.instance;
      service.setLocation(
        PluginLocationService(
          fallback: Future.value(primary),
          additionalLocations: [Future.value(legacy)],
        ),
      );

      final found = await service.plugins;
      final plugin = found.firstWhere((p) => p.name == 'shared');
      expect(plugin.source.path, startsWith(primary.path));
    });

    test('skips non-existent additional locations gracefully', () async {
      final primary = Directory(p.join(tmp.path, 'primary'))..createSync();
      _createFakePlugin(primary, 'myTheme');
      final nonExistent = Directory(p.join(tmp.path, 'does_not_exist'));

      final service = FlowyPluginService.instance;
      service.setLocation(
        PluginLocationService(
          fallback: Future.value(primary),
          additionalLocations: [Future.value(nonExistent)],
        ),
      );

      final found = await service.plugins;
      expect(found.map((p) => p.name), contains('myTheme'));
    });

    test('AppTheme.fromName resolves a plugin theme from the legacy directory',
        () async {
      final primary = Directory(p.join(tmp.path, 'primary'))..createSync();
      final legacy = Directory(p.join(tmp.path, 'legacy'))..createSync();
      _createFakePlugin(legacy, 'retroTheme');

      final service = FlowyPluginService.instance;
      service.setLocation(
        PluginLocationService(
          fallback: Future.value(primary),
          additionalLocations: [Future.value(legacy)],
        ),
      );

      final theme = await AppTheme.fromName('retroTheme', pluginService: service);
      expect(theme.themeName, equals('retroTheme'));
      expect(theme.builtIn, isFalse);
    });
  });
}
