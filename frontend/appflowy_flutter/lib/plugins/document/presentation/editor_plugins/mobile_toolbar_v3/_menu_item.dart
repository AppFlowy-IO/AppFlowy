import 'package:flowy_svg/flowy_svg.dart';
import 'package:flutter/material.dart';

class MenuItem extends StatelessWidget {
  const MenuItem({
    super.key,
    required this.isSelected,
    required this.icon,
  });

  final bool isSelected;
  final FlowySvgData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 62,
      height: 44,
      decoration: ShapeDecoration(
        color: isSelected ? const Color(0xFF00BCF0) : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
      child: FlowySvg(
        icon,
        color: isSelected ? Colors.white : null,
      ),
    );
  }
}

class MenuWrapper extends StatelessWidget {
  const MenuWrapper({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        shadows: const [
          BoxShadow(
            color: Color(0x2D000000),
            blurRadius: 20,
            offset: Offset(0, 10),
            spreadRadius: 0,
          ),
        ],
      ),
      child: child,
    );
  }
}
