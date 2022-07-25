import 'package:app_flowy/workspace/presentation/widgets/toggle/toggle_style.dart';
import 'package:flutter/widgets.dart';

class Toggle extends StatelessWidget {
  final ToggleStyle style;
  final bool value;
  final void Function(bool) onChanged;
  final EdgeInsets padding;

  const Toggle({
    Key? key,
    required this.value,
    required this.onChanged,
    required this.style,
    this.padding = const EdgeInsets.all(8.0),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (() => onChanged(value)),
      child: Padding(
        padding: padding,
        child: Stack(
          children: [
            Container(
              height: style.height,
              width: style.width,
              decoration: BoxDecoration(
                color: value ? style.activeBackgroundColor : style.inactiveBackgroundColor,
                borderRadius: BorderRadius.circular(style.height / 2),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 150),
              top: (style.height - style.thumbRadius) / 2,
              left: value ? style.width - style.thumbRadius - 1 : 1,
              child: Container(
                height: style.thumbRadius,
                width: style.thumbRadius,
                decoration: BoxDecoration(
                  color: style.thumbColor,
                  borderRadius: BorderRadius.circular(style.thumbRadius / 2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
