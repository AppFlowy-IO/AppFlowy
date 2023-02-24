import 'package:flutter_test/flutter_test.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

void main() async {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('keybinding_test.dart', () {
    test('keybinding parse(cmd+shift+alt+ctrl+a)', () {
      const command = 'cmd+shift+alt+ctrl+a';
      final keybinding = Keybinding.parse(command);
      expect(keybinding.isAltPressed, true);
      expect(keybinding.isShiftPressed, true);
      expect(keybinding.isMetaPressed, true);
      expect(keybinding.isControlPressed, true);
      expect(keybinding.keyLabel, 'a');
    });

    test('keybinding parse(cmd+shift+alt+a)', () {
      const command = 'cmd+shift+alt+a';
      final keybinding = Keybinding.parse(command);
      expect(keybinding.isAltPressed, true);
      expect(keybinding.isShiftPressed, true);
      expect(keybinding.isMetaPressed, true);
      expect(keybinding.isControlPressed, false);
      expect(keybinding.keyLabel, 'a');
    });

    test('keybinding parse(cmd+shift+ctrl+a)', () {
      const command = 'cmd+shift+ctrl+a';
      final keybinding = Keybinding.parse(command);
      expect(keybinding.isAltPressed, false);
      expect(keybinding.isShiftPressed, true);
      expect(keybinding.isMetaPressed, true);
      expect(keybinding.isControlPressed, true);
      expect(keybinding.keyLabel, 'a');
    });

    test('keybinding parse(cmd+alt+ctrl+a)', () {
      const command = 'cmd+alt+ctrl+a';
      final keybinding = Keybinding.parse(command);
      expect(keybinding.isAltPressed, true);
      expect(keybinding.isShiftPressed, false);
      expect(keybinding.isMetaPressed, true);
      expect(keybinding.isControlPressed, true);
      expect(keybinding.keyLabel, 'a');
    });

    test('keybinding parse(shift+alt+ctrl+a)', () {
      const command = 'shift+alt+ctrl+a';
      final keybinding = Keybinding.parse(command);
      expect(keybinding.isAltPressed, true);
      expect(keybinding.isShiftPressed, true);
      expect(keybinding.isMetaPressed, false);
      expect(keybinding.isControlPressed, true);
      expect(keybinding.keyLabel, 'a');
    });

    test('keybinding copyWith', () {
      const command = 'shift+alt+ctrl+a';
      final keybinding =
          Keybinding.parse(command).copyWith(isMetaPressed: true);
      expect(keybinding.isAltPressed, true);
      expect(keybinding.isShiftPressed, true);
      expect(keybinding.isMetaPressed, true);
      expect(keybinding.isControlPressed, true);
      expect(keybinding.keyLabel, 'a');
    });

    test('keybinding equal', () {
      const command = 'cmd+shift+alt+ctrl+a';
      expect(Keybinding.parse(command), Keybinding.parse(command));
    });

    test('keybinding toMap', () {
      const command = 'cmd+shift+alt+ctrl+a';
      final keybinding = Keybinding.parse(command);
      expect(keybinding, Keybinding.fromMap(keybinding.toMap()));
    });
  });
}
