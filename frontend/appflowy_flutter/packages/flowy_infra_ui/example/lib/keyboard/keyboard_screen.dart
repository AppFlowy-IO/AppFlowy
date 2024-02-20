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
  const KeyboardScreen({super.key});

  @override
  State<KeyboardScreen> createState() => _KeyboardScreenState();
}

class _KeyboardScreenState extends State<KeyboardScreen> {
  bool _isKeyboardVisible = false;
  final TextEditingController _controller =
      TextEditingController(text: 'Hello Flowy');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    child: Text(
                      'Keyboard Visible: $_isKeyboardVisible',
                      style: const TextStyle(fontSize: 24.0),
                    ),
                  ),
                  TextField(
                    style: const TextStyle(fontSize: 20),
                    controller: _controller,
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
