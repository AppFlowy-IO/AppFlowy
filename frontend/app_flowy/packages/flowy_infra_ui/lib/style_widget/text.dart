import 'package:flutter/material.dart';

@Deprecated('Use `Theme.of(context).textTheme` instead')
class FlowyText extends StatelessWidget {
  const FlowyText(
    this.title, {
    Key? key,
    this.overflow = TextOverflow.ellipsis,
    this.fontSize = 16,
    this.fontWeight = FontWeight.w400,
    this.textAlign,
    this.color,
  }) : super(key: key);

  final String title;
  final TextOverflow overflow;
  final double fontSize;
  final FontWeight fontWeight;
  final TextAlign? textAlign;
  final Color? color;

  const FlowyText.semibold(
    this.title, {
    Key? key,
    this.fontSize = 16,
    TextOverflow? overflow,
    this.color,
    this.textAlign,
  })  : fontWeight = FontWeight.w600,
        overflow = overflow ?? TextOverflow.ellipsis,
        super(key: key);

  const FlowyText.medium(
    this.title, {
    Key? key,
    this.fontSize = 16,
    TextOverflow? overflow,
    this.color,
    this.textAlign,
  })  : fontWeight = FontWeight.w500,
        overflow = overflow ?? TextOverflow.ellipsis,
        super(key: key);

  const FlowyText.regular(
    this.title, {
    Key? key,
    this.fontSize = 16,
    TextOverflow? overflow,
    this.color,
    this.textAlign,
  })  : fontWeight = FontWeight.w400,
        overflow = overflow ?? TextOverflow.ellipsis,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(title,
        overflow: overflow,
        softWrap: false,
        style: TextStyle(
          color: color ?? Theme.of(context).textTheme.bodyText1!.color,
          fontWeight: fontWeight,
          fontSize: fontSize + 2,
          fontFamily: 'Mulish',
        ));
  }
}
