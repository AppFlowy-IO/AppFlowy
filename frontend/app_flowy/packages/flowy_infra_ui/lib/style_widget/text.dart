import 'package:flutter/material.dart';

class FlowyText extends StatelessWidget {
  final String title;
  final TextOverflow? overflow;
  final double? fontSize;
  final FontWeight? fontWeight;
  final TextAlign? textAlign;
  final int? maxLines;
  final Color? color;
  final TextDecoration? decoration;

  const FlowyText(
    this.title, {
    Key? key,
    this.overflow = TextOverflow.clip,
    this.fontSize,
    this.fontWeight,
    this.textAlign,
    this.color,
    this.maxLines = 1,
    this.decoration,
  }) : super(key: key);

  const FlowyText.regular(
    this.title, {
    Key? key,
    this.fontSize,
    this.overflow,
    this.color,
    this.textAlign,
    this.maxLines = 1,
    this.decoration,
  })  : fontWeight = FontWeight.w400,
        super(key: key);

  const FlowyText.medium(
    this.title, {
    Key? key,
    this.fontSize,
    this.overflow,
    this.color,
    this.textAlign,
    this.maxLines = 1,
    this.decoration,
  })  : fontWeight = FontWeight.w500,
        super(key: key);

  const FlowyText.semibold(
    this.title, {
    Key? key,
    this.fontSize,
    this.overflow,
    this.color,
    this.textAlign,
    this.maxLines = 1,
    this.decoration,
  })  : fontWeight = FontWeight.w600,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      maxLines: maxLines,
      textAlign: textAlign,
      overflow: overflow ?? TextOverflow.clip,
      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: color,
            decoration: decoration,
          ),
    );
  }
}
