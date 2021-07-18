import 'package:flowy_infra_ui/flowy_infra_ui_web.dart';
import 'package:flutter/material.dart';
import '../home/demo_item.dart';

class KeyboardItem extends DemoItem {
  @override
  String buildTitle() => 'Keyboard Listener';

  @override
  void handleTap(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          return const KeyboardScreen();
        },
      ),
    );
  }
}

class KeyboardScreen extends StatefulWidget {
  const KeyboardScreen({Key? key}) : super(key: key);

  @override
  _KeyboardScreenState createState() => _KeyboardScreenState();
}

class _KeyboardScreenState extends State<KeyboardScreen> {
  bool _isKeyboardVisible = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Keyboard Visibility Demo'),
      ),
      body: KeyboardVisibilityDetector(
        onKeyboardVisibilityChange: (isKeyboardVisible) {
          setState(() => _isKeyboardVisible = isKeyboardVisible);
        },
        child: GestureDetector(
          onTap: () => _dismissKeyboard(context),
          behavior: HitTestBehavior.translucent,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36),
            child: Center(
              child: Column(
                children: [
                  Text('Keyboard Visible: $_isKeyboardVisible'),
                  TextField(
                    style: const TextStyle(fontSize: 20),
                    controller: TextEditingController(text: 'Test'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _dismissKeyboard(BuildContext context) {
    final currentFocus = FocusScope.of(context);

    if (!currentFocus.hasPrimaryFocus && currentFocus.hasFocus) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }
}
