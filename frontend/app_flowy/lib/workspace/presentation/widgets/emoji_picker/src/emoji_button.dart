import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';

import 'package:app_flowy/workspace/presentation/stack_page/doc/widget/toolbar/toolbar_icon_button.dart';
import 'package:app_flowy/workspace/presentation/widgets/emoji_picker/emoji_picker.dart';

final toggleEmojiPicker = LogicalKeySet(
  LogicalKeyboardKey.meta,
  LogicalKeyboardKey.shift,
  LogicalKeyboardKey.question,
);

class IncrementIntent extends Intent {}

class FlowyEmojiStyleButton extends StatefulWidget {
  // final Attribute attribute;
  final String normalIcon;
  final double iconSize;
  final QuillController controller;
  final String tooltipText;

  const FlowyEmojiStyleButton({
    // required this.attribute,
    required this.normalIcon,
    required this.controller,
    required this.tooltipText,
    this.iconSize = defaultIconSize,
    Key? key,
  }) : super(key: key);

  @override
  _EmojiStyleButtonState createState() => _EmojiStyleButtonState();
}

class _EmojiStyleButtonState extends State<FlowyEmojiStyleButton> {
  bool _isToggled = false;
  // Style get _selectionStyle => widget.controller.getSelectionStyle();
  final GlobalKey emojiButtonKey = GlobalKey();
  OverlayEntry _entry = OverlayEntry(builder: (context) => Container());
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

    //TODO @gaganyadav80: FIXIT: Keyboard shortcut not working.
    return FocusableActionDetector(
      autofocus: true,
      shortcuts: {toggleEmojiPicker: IncrementIntent()},
      actions: {IncrementIntent: CallbackAction(onInvoke: (intent) => _toggleAttribute())},
      child: ToolbarIconButton(
        key: emojiButtonKey,
        onPressed: _toggleAttribute,
        width: widget.iconSize * kIconButtonFactor,
        isToggled: _isToggled,
        iconName: widget.normalIcon,
        tooltipText: widget.tooltipText,
      ),
    );
  }

  // @override
  // void didUpdateWidget(covariant FlowyEmojiStyleButton oldWidget) {
  //   super.didUpdateWidget(oldWidget);
  //   if (oldWidget.controller != widget.controller) {
  //     oldWidget.controller.removeListener(_didChangeEditingValue);
  //     widget.controller.addListener(_didChangeEditingValue);
  //     _isToggled = _getIsToggled(_selectionStyle.attributes);
  //   }
  // }

  // @override
  // void dispose() {
  //   widget.controller.removeListener(_didChangeEditingValue);
  //   super.dispose();
  // }

  // void _didChangeEditingValue() {
  //   setState(() => _isToggled = _getIsToggled(_selectionStyle.attributes));
  // }

  // bool _getIsToggled(Map<String, Attribute> attrs) {
  //   return _entry.mounted;
  // }

  void _toggleAttribute() {
    if (_entry.mounted) {
      _entry.remove();
      setState(() => _isToggled = false);
    } else {
      RenderBox box = emojiButtonKey.currentContext?.findRenderObject() as RenderBox;
      Offset position = box.localToGlobal(Offset.zero);

      // final window = await getWindowInfo();

      _entry = OverlayEntry(
        builder: (BuildContext context) => BuildEmojiPickerView(
          controller: widget.controller,
          offset: position,
        ),
      );

      Overlay.of(context)!.insert(_entry);
      setState(() => _isToggled = true);
    }

    //? @gaganyadav80: INFO: throws error when using TextField with FlowyOverlay.
    // FlowyOverlay.of(context).insertWithRect(
    //   widget: BuildEmojiPickerView(controller: widget.controller),
    //   identifier: 'overlay_emoji_picker',
    //   anchorPosition: Offset(position.dx + 40, position.dy - 10),
    //   anchorSize: window.frame.size,
    //   anchorDirection: AnchorDirection.topLeft,
    //   style: FlowyOverlayStyle(blur: true),
    // );
  }
}

class BuildEmojiPickerView extends StatefulWidget {
  const BuildEmojiPickerView({Key? key, required this.controller, this.offset}) : super(key: key);

  final QuillController controller;
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
          top: widget.offset!.dy - MediaQuery.of(context).size.height / 2.83 - 30,
          left: widget.offset!.dx - MediaQuery.of(context).size.width / 3.92 + 40,
          child: Material(
            borderRadius: BorderRadius.circular(8.0),
            child: SizedBox(
              //TODO @gaganyadav80: FIXIT: Gets too large when fullscreen.
              height: MediaQuery.of(context).size.height / 2.83 + 20,
              width: MediaQuery.of(context).size.width / 3.92,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: EmojiPicker(
                  onEmojiSelected: (category, emoji) {
                    // widget.controller.document.insert(widget.controller.document.length - 1, emoji.emoji);
                  },
                  config: const Config(
                    columns: 8,
                    emojiSizeMax: 28,
                    bgColor: Color(0xffF2F2F2),
                    iconColor: Colors.grey,
                    iconColorSelected: Color(0xff333333),
                    indicatorColor: Color(0xff333333),
                    progressIndicatorColor: Color(0xff333333),
                    buttonMode: ButtonMode.CUPERTINO,
                    //TODO @gaganyadav80: Remove after done
                    initCategory: Category.SMILEYS,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
