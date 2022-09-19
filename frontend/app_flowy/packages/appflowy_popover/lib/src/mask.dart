import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class _PopoverMask extends StatefulWidget {
  final void Function() onTap;
  final void Function()? onExit;
  final Decoration? decoration;

  const _PopoverMask(
      {Key? key,
      required this.onTap,
      this.onExit,
      this.decoration =
          const BoxDecoration(color: Color.fromARGB(0, 244, 67, 54))})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _PopoverMaskState();
}

class _PopoverMaskState extends State<_PopoverMask> {
  @override
  void initState() {
    HardwareKeyboard.instance.addHandler(_handleGlobalKeyEvent);
    super.initState();
  }

  bool _handleGlobalKeyEvent(KeyEvent event) {
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      if (widget.onExit != null) {
        widget.onExit!();
      }

      return true;
    }
    return false;
  }

  @override
  void deactivate() {
    HardwareKeyboard.instance.removeHandler(_handleGlobalKeyEvent);
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: widget.decoration,
      ),
    );
  }
}
