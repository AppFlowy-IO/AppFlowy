import 'package:flowy_infra/theme.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

class FlowyText extends StatelessWidget {
  final String title;
  final TextOverflow overflow;
  final double fontSize;
  final FontWeight fontWeight;
  final Color? color;
  const FlowyText(
    this.title, {
    Key? key,
    this.overflow = TextOverflow.ellipsis,
    this.fontSize = 16,
    this.fontWeight = FontWeight.w400,
    this.color,
  }) : super(key: key);

  const FlowyText.semibold(this.title, {Key? key, this.fontSize = 16, TextOverflow? overflow, this.color})
      : fontWeight = FontWeight.w600,
        overflow = overflow ?? TextOverflow.ellipsis,
        super(key: key);

  const FlowyText.medium(this.title, {Key? key, this.fontSize = 16, TextOverflow? overflow, this.color})
      : fontWeight = FontWeight.w500,
        overflow = overflow ?? TextOverflow.ellipsis,
        super(key: key);

  const FlowyText.regular(this.title, {Key? key, this.fontSize = 16, TextOverflow? overflow, this.color})
      : fontWeight = FontWeight.w400,
        overflow = overflow ?? TextOverflow.ellipsis,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    final textColor = color ?? theme.shader1;
    return Text(title,
        overflow: overflow,
        softWrap: false,
        style: TextStyle(
          color: textColor,
          fontWeight: fontWeight,
          fontSize: fontSize + 2,
        ));
  }
}
