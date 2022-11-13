import 'package:flutter/material.dart';
import 'package:app_flowy/workspace/presentation/widgets/emoji_picker/emoji_picker.dart';

class FlowyEmojiStyleButton extends StatefulWidget {
  // final Attribute attribute;
  final String normalIcon;
  // TODO: enable insert emoji in appflowy_editor
  // final QuillController controller;
  final String tooltipText;

  const FlowyEmojiStyleButton({
    // required this.attribute,
    required this.normalIcon,
    required this.tooltipText,
    Key? key,
  }) : super(key: key);

  @override
  EmojiStyleButtonState createState() => EmojiStyleButtonState();
}

class EmojiStyleButtonState extends State<FlowyEmojiStyleButton> {
  // Style get _selectionStyle => widget.controller.getSelectionStyle();
  final GlobalKey emojiButtonKey = GlobalKey();
  OverlayEntry? _entry;
  // final FocusNode _keyFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // _isToggled = _getIsToggled(_selectionStyle.attributes);
    // widget.controller.addListener(_didChangeEditingValue);
  }

  @override
  Widget build(BuildContext context) {
    // debugPrint(MediaQuery.of(context).size.width.toString());
    // debugPrint(MediaQuery.of(context).size.height.toString());

    // return ToolbarIconButton(
    //   key: emojiButtonKey,
    //   onPressed: _toggleAttribute,
    //   width: widget.iconSize * kIconButtonFactor,
    //   isToggled: _isToggled,
    //   iconName: widget.normalIcon,
    //   tooltipText: widget.tooltipText,
    // );
    return Container();
  }

  @override
  void dispose() {
    _entry?.remove();
    super.dispose();
  }

  // void _toggleAttribute() {
  //   if (_entry?.mounted ?? false) {
  //     _entry?.remove();
  //     _entry = null;
  //     setState(() => _isToggled = false);
  //   } else {
  //     RenderBox box =
  //         emojiButtonKey.currentContext?.findRenderObject() as RenderBox;
  //     Offset position = box.localToGlobal(Offset.zero);

  //     // final window = await getWindowInfo();

  //     _entry = OverlayEntry(
  //       builder: (BuildContext context) => BuildEmojiPickerView(
  //         controller: widget.controller,
  //         offset: position,
  //       ),
  //     );

  //     Overlay.of(context)!.insert(_entry!);
  //     setState(() => _isToggled = true);
  //   }

  // }
}

class BuildEmojiPickerView extends StatefulWidget {
  const BuildEmojiPickerView({Key? key, this.offset}) : super(key: key);
  final Offset? offset;

  @override
  State<BuildEmojiPickerView> createState() => _BuildEmojiPickerViewState();
}

class _BuildEmojiPickerViewState extends State<BuildEmojiPickerView> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          //TODO @gaganyadav80: Not sure about the calculated position.
          top: widget.offset!.dy -
              MediaQuery.of(context).size.height / 2.83 -
              30,
          left:
              widget.offset!.dx - MediaQuery.of(context).size.width / 3.92 + 40,
          child: Material(
            borderRadius: BorderRadius.circular(8.0),
            child: SizedBox(
              //TODO @gaganyadav80: FIXIT: Gets too large when fullscreen.
              height: MediaQuery.of(context).size.height / 2.83 + 20,
              width: MediaQuery.of(context).size.width / 3.92,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: EmojiPicker(
                  onEmojiSelected: (category, emoji) => insertEmoji(emoji),
                  config: const Config(
                    columns: 8,
                    emojiSizeMax: 28,
                    bgColor: Color(0xffF2F2F2),
                    iconColor: Colors.grey,
                    iconColorSelected: Color(0xff333333),
                    indicatorColor: Color(0xff333333),
                    progressIndicatorColor: Color(0xff333333),
                    buttonMode: ButtonMode.CUPERTINO,
                    initCategory: Category.RECENT,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void insertEmoji(Emoji emoji) {
    // final baseOffset = widget.controller.selection.baseOffset;
    // final extentOffset = widget.controller.selection.extentOffset;
    // final replaceLen = extentOffset - baseOffset;
    // final selection = widget.controller.selection.copyWith(
    //   baseOffset: baseOffset + emoji.emoji.length,
    //   extentOffset: baseOffset + emoji.emoji.length,
    // );

    // widget.controller
    //     .replaceText(baseOffset, replaceLen, emoji.emoji, selection);
  }
}
