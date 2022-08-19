import 'package:appflowy_editor/src/infra/log.dart';
import 'package:flutter_test/flutter_test.dart';
import 'test_editor.dart';

void main() async {
  group('log.dart', () {
    testWidgets('test LogConfiguration in EditorState', (tester) async {
      TestWidgetsFlutterBinding.ensureInitialized();

      const text = 'Welcome to Appflowy 😁';

      final List<String> logs = [];

      final editor = tester.editor;
      editor.editorState.logConfiguration
        ..level = LogLevel.all
        ..handler = (message) {
          logs.add(message);
        };

      Log.editor.debug(text);
      expect(logs.last.contains('DEBUG'), true);
      expect(logs.length, 1);
    });

    test('test LogLevel.all', () {
      const text = 'Welcome to Appflowy 😁';

      final List<String> logs = [];
      LogConfiguration()
        ..level = LogLevel.all
        ..handler = (message) {
          logs.add(message);
        };

      Log.editor.debug(text);
      expect(logs.last.contains('DEBUG'), true);
      Log.editor.info(text);
      expect(logs.last.contains('INFO'), true);
      Log.editor.warn(text);
      expect(logs.last.contains('WARN'), true);
      Log.editor.error(text);
      expect(logs.last.contains('ERROR'), true);

      expect(logs.length, 4);
    });

    test('test LogLevel.off', () {
      const text = 'Welcome to Appflowy 😁';

      final List<String> logs = [];
      LogConfiguration()
        ..level = LogLevel.off
        ..handler = (message) {
          logs.add(message);
        };

      Log.editor.debug(text);
      Log.editor.info(text);
      Log.editor.warn(text);
      Log.editor.error(text);

      expect(logs.length, 0);
    });

    test('test LogLevel.error', () {
      const text = 'Welcome to Appflowy 😁';

      final List<String> logs = [];
      LogConfiguration()
        ..level = LogLevel.error
        ..handler = (message) {
          logs.add(message);
        };

      Log.editor.debug(text);
      Log.editor.info(text);
      Log.editor.warn(text);
      Log.editor.error(text);

      expect(logs.length, 1);
    });

    test('test LogLevel.warn', () {
      const text = 'Welcome to Appflowy 😁';

      final List<String> logs = [];
      LogConfiguration()
        ..level = LogLevel.warn
        ..handler = (message) {
          logs.add(message);
        };

      Log.editor.debug(text);
      Log.editor.info(text);
      Log.editor.warn(text);
      Log.editor.error(text);

      expect(logs.length, 2);
    });

    test('test LogLevel.info', () {
      const text = 'Welcome to Appflowy 😁';

      final List<String> logs = [];
      LogConfiguration()
        ..level = LogLevel.info
        ..handler = (message) {
          logs.add(message);
        };

      Log.editor.debug(text);
      Log.editor.info(text);
      Log.editor.warn(text);
      Log.editor.error(text);

      expect(logs.length, 3);
    });

    test('test LogLevel.debug', () {
      const text = 'Welcome to Appflowy 😁';

      final List<String> logs = [];
      LogConfiguration()
        ..level = LogLevel.debug
        ..handler = (message) {
          logs.add(message);
        };

      Log.editor.debug(text);
      Log.editor.info(text);
      Log.editor.warn(text);
      Log.editor.error(text);

      expect(logs.length, 4);
    });

    test('test logger', () {
      const text = 'Welcome to Appflowy 😁';

      final List<String> logs = [];
      LogConfiguration()
        ..level = LogLevel.all
        ..handler = (message) {
          logs.add(message);
        };

      Log.editor.debug(text);
      expect(logs.last.contains('editor'), true);

      Log.selection.debug(text);
      expect(logs.last.contains('selection'), true);

      Log.keyboard.debug(text);
      expect(logs.last.contains('keyboard'), true);

      Log.input.debug(text);
      expect(logs.last.contains('input'), true);

      Log.scroll.debug(text);
      expect(logs.last.contains('scroll'), true);

      Log.ui.debug(text);
      expect(logs.last.contains('ui'), true);

      expect(logs.length, 6);
    });
  });
}
