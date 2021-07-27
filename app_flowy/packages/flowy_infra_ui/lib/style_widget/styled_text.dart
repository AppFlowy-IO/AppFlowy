import 'package:flutter/widgets.dart';

class StyledText extends StatelessWidget {
  final String title;
  final TextOverflow overflow;
  final double fontSize;
  const StyledText(
    this.title, {
    Key? key,
    this.overflow = TextOverflow.ellipsis,
    this.fontSize = 16,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      overflow: overflow,
      softWrap: false,
      style: TextStyle(fontSize: fontSize),
    );
  }
}
