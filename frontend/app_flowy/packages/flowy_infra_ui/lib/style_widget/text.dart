import 'package:flowy_infra/text_style.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FlowyText extends StatelessWidget {
  final String title;
  final TextOverflow? overflow;
  final double fontSize;
  final FontWeight fontWeight;
  final TextAlign? textAlign;
  final int? maxLines;
  final Color? color;

  const FlowyText(
    this.title, {
    Key? key,
    this.overflow = TextOverflow.clip,
    this.fontSize = 16,
    this.fontWeight = FontWeight.w400,
    this.textAlign,
    this.color,
    this.maxLines = 1,
  }) : super(key: key);

  const FlowyText.semibold(
    this.title, {
    Key? key,
    this.fontSize = 16,
    this.overflow,
    this.color,
    this.textAlign,
    this.maxLines = 1,
  })  : fontWeight = FontWeight.w600,
        super(key: key);

  const FlowyText.medium(
    this.title, {
    Key? key,
    this.fontSize = 16,
    this.overflow,
    this.color,
    this.textAlign,
    this.maxLines = 1,
  })  : fontWeight = FontWeight.w500,
        super(key: key);

  const FlowyText.regular(
    this.title, {
    Key? key,
    this.fontSize = 16,
    this.overflow,
    this.color,
    this.textAlign,
    this.maxLines = 1,
  })  : fontWeight = FontWeight.w400,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return Text(
      title,
      maxLines: maxLines,
      textAlign: textAlign,
      overflow: overflow ?? TextOverflow.clip,
      style: TextStyles.general(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color ?? theme.textColor,
      ),
    );
  }
}
