import 'package:appflowy/startup/tasks/prelude.dart';
import 'package:keyboard_height_plugin/keyboard_height_plugin.dart';

typedef KeyboardHeightCallback = void Function(double height);

// the KeyboardHeightPlugin only accepts one listener, so we need to create a
//  singleton class to manage the multiple listeners.
class KeyboardHeightObserver {
  KeyboardHeightObserver._() {
    _keyboardHeightPlugin.onKeyboardHeightChanged((height) {
      notify(height);

      currentKeyboardHeight = height;
    });
  }

  static final KeyboardHeightObserver instance = KeyboardHeightObserver._();
  static double currentKeyboardHeight = 0;

  final List<KeyboardHeightCallback> _listeners = [];
  final KeyboardHeightPlugin _keyboardHeightPlugin = KeyboardHeightPlugin();

  void addListener(KeyboardHeightCallback listener) {
    _listeners.add(listener);
  }

  void removeListener(KeyboardHeightCallback listener) {
    _listeners.remove(listener);
  }

  void dispose() {
    _listeners.clear();
    _keyboardHeightPlugin.dispose();
  }

  void notify(double height) {
    // the keyboard height will notify twice with the same value on Android 14
    if (ApplicationInfo.androidSDKVersion == 34) {
      if (height == 0 && currentKeyboardHeight == 0) {
        return;
      }
    }
    for (final listener in _listeners) {
      listener(height);
    }
  }
}
