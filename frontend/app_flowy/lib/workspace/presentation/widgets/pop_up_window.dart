import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/widget/rounded_input_field.dart';
import 'package:flutter/material.dart';
import 'package:window_size/window_size.dart';

class FlowyPoppuWindow extends StatelessWidget {
  final Widget child;
  const FlowyPoppuWindow({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      child: child,
      type: MaterialType.transparency,
    );
  }

  static Future<void> show(
    BuildContext context, {
    required Widget child,
    required Size size,
  }) async {
    final window = await getWindowInfo();

    FlowyOverlay.of(context).insertWithRect(
      widget: SizedBox.fromSize(
        size: size,
        child: FlowyPoppuWindow(child: child),
      ),
      identifier: 'FlowyPoppuWindow',
      anchorPosition: Offset(-size.width / 2.0, -size.height / 2.0),
      anchorSize: window.frame.size,
      anchorDirection: AnchorDirection.center,
      style: FlowyOverlayStyle(blur: false),
    );
  }
}

class PopupTextField extends StatelessWidget {
  final void Function(String) textDidChange;
  const PopupTextField({
    Key? key,
    required this.textDidChange,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RoundedInputField(
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      hintText: '',
      normalBorderColor: const Color(0xffbdbdbd),
      onChanged: textDidChange,
    );
  }

  static void show({required BuildContext context, required Size size, required void Function(String) textDidChange}) {
    FlowyPoppuWindow.show(
      context,
      size: size,
      child: PopupTextField(textDidChange: textDidChange),
    );
  }
}
