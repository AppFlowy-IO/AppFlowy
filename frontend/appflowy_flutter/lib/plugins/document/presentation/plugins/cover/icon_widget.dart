import 'package:flowy_infra/size.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class EmojiIconWidget extends StatefulWidget {
  final String? emoji;
  final void Function() onEmojiTapped;

  const EmojiIconWidget({
    super.key,
    required this.emoji,
    required this.onEmojiTapped,
  });

  @override
  State<EmojiIconWidget> createState() => _EmojiIconWidgetState();
}

class _EmojiIconWidgetState extends State<EmojiIconWidget> {
  bool hover = true;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (event) {
        setHidden(false);
      },
      onExit: (event) {
        setHidden(true);
      },
      child: Container(
        height: 130,
        width: 130,
        margin: const EdgeInsets.only(top: 18),
        decoration: BoxDecoration(
          color: !hover
              ? Theme.of(context).colorScheme.secondary
              : Colors.transparent,
          borderRadius: Corners.s8Border,
        ),
        alignment: Alignment.center,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            FlowyText(
              widget.emoji.toString(),
              fontSize: 80,
            ),
          ],
        ),
      ),
    );
  }

  void setHidden(bool value) {
    if (hover == value) return;
    setState(() {
      hover = value;
    });
  }
}
