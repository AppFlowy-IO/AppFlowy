import 'package:flutter/material.dart';

class TextBlockWithIcon extends StatefulWidget {
  const TextBlockWithIcon({
    super.key,
    required this.textBlockKey,
  });

  final GlobalKey textBlockKey;

  @override
  State<TextBlockWithIcon> createState() => _TextBlockWithIconState();
}

class _TextBlockWithIconState extends State<TextBlockWithIcon> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
