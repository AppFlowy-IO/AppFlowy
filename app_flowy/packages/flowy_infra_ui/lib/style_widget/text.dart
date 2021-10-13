import 'package:flowy_infra/theme.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

class FlowyText extends StatelessWidget {
  final String title;
  final TextOverflow overflow;
  final double fontSize;
  final FontWeight fontWeight;
  const FlowyText(
    this.title, {
    Key? key,
    this.overflow = TextOverflow.ellipsis,
    this.fontSize = 16,
    this.fontWeight = FontWeight.w500,
  }) : super(key: key);

  const FlowyText.semibold(this.title, {Key? key, this.fontSize = 16, TextOverflow? overflow})
      : fontWeight = FontWeight.w600,
        overflow = overflow ?? TextOverflow.ellipsis,
        super(key: key);

  const FlowyText.medium(this.title, {Key? key, this.fontSize = 16, TextOverflow? overflow})
      : fontWeight = FontWeight.w500,
        overflow = overflow ?? TextOverflow.ellipsis,
        super(key: key);

  const FlowyText.regular(this.title, {Key? key, this.fontSize = 16, TextOverflow? overflow})
      : fontWeight = FontWeight.w400,
        overflow = overflow ?? TextOverflow.ellipsis,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return Text(title,
        overflow: overflow,
        softWrap: false,
        style: TextStyle(
          color: theme.shader1,
          fontWeight: fontWeight,
          fontSize: fontSize + 2,
        ));
  }
}
