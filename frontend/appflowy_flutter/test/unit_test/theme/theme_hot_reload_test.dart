import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flowy_infra/colorscheme/default_colorscheme.dart';
import 'package:flowy_infra/plugins/service/models/flowy_dynamic_plugin.dart';
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
    tmp = Directory.systemTemp.createTempSync('appflowy_hotreload_test_');
  });

  tearDown(() {
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  group('Theme hot-reload — file changes detected on disk', () {
    test(
        'FlowyDynamicPlugin.decode re-reads files so updated JSON is picked up',
        () async {
      final primary = Directory(p.join(tmp.path, 'primary'))..createSync();
      final pluginDir = _createFakePlugin(primary, 'hotTheme');

      final original = await FlowyDynamicPlugin.decode(src: pluginDir);
      expect(original.theme, isNotNull);
      final originalLight = original.theme!.lightTheme;

      final lightFile = File(p.join(pluginDir.path, 'hotTheme.light.json'));
      final json =
          jsonDecode(lightFile.readAsStringSync()) as Map<String, dynamic>;
      json['primary'] = '0xFFFF0000';
      lightFile.writeAsStringSync(jsonEncode(json));

      final reloaded = await FlowyDynamicPlugin.decode(src: pluginDir);
      expect(reloaded.theme, isNotNull);
      expect(
        reloaded.theme!.lightTheme.primary,
        isNot(equals(originalLight.primary)),
      );
    });

    test('Directory.watch emits events when theme JSON files change', () async {
      final primary = Directory(p.join(tmp.path, 'primary'))..createSync();
      final pluginDir = _createFakePlugin(primary, 'watchTheme');

      final events = <FileSystemEvent>[];
      final subscription = pluginDir.watch(recursive: true).listen(events.add);

      await Future<void>.delayed(const Duration(milliseconds: 200));

      final lightFile =
          File(p.join(pluginDir.path, 'watchTheme.light.json'));
      lightFile.writeAsStringSync('{}');

      await Future<void>.delayed(const Duration(milliseconds: 500));
      await subscription.cancel();

      expect(events, isNotEmpty, reason: 'File watcher should have fired');
    });
  });
}
