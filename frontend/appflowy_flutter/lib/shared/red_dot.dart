import 'package:flutter/widgets.dart';

class NotificationRedDot extends StatelessWidget {
  const NotificationRedDot({
    super.key,
    this.size = 6,
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: ShapeDecoration(
        color: const Color(0xFFFF2214),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}
