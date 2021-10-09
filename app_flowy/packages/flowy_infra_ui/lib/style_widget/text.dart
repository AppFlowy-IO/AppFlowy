import 'package:flowy_infra/theme.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

class FlowyText extends StatelessWidget {
  final String title;
  final TextOverflow overflow;
  final double fontSize;
  const FlowyText(
    this.title, {
    Key? key,
    this.overflow = TextOverflow.ellipsis,
    this.fontSize = 16,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return Text(title,
        overflow: overflow,
        softWrap: false,
        style: TextStyle(
          color: theme.shader1,
          fontWeight: FontWeight.w500,
          fontSize: fontSize + 2,
        ));
  }
}
