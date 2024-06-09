import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:appflowy/workspace/presentation/settings/widgets/emoji_picker/src/emoji_picker.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/emoji_picker/src/emoji_picker_builder.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/emoji_picker/src/models/emoji_model.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:collection/collection.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';

const int emojiSearchLimit = 40;
const int emojiNumberPerRow = 8;
const double emojiSizeMax = 28;

const Offset menuOffset = Offset(0, 8.0);
const double menuHeight = 200.0;
const double menuWidth = 300.0;

final Map<LogicalKeyboardKey, int> arrowKeys = {
  LogicalKeyboardKey.arrowRight: 1,
  LogicalKeyboardKey.arrowLeft: -1,
  LogicalKeyboardKey.arrowDown: emojiNumberPerRow,
  LogicalKeyboardKey.arrowUp: -emojiNumberPerRow,
};

class EmojiShortcutPickerView extends EmojiPickerBuilder {
  const EmojiShortcutPickerView(
    super.config,
    super.state,
    this.editorState,
    this.shortcutCharacter,
    this.onExit, {
    super.key,
  });

  final VoidCallback onExit;
  final EditorState editorState;
  final String shortcutCharacter;

  @override
  EmojiShortcutPickerViewState createState() => EmojiShortcutPickerViewState();
}

class EmojiShortcutPickerViewState extends State<EmojiShortcutPickerView>
    with TickerProviderStateMixin {
  final FocusNode _focusNode = FocusNode(debugLabel: 'emoji_shortcut_picker');
  final TextEditingController _emojiController = TextEditingController();
  List<Emoji> searchEmojiList = [];

  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      _searchEmoji();
    });
  }

  @override
  void dispose() {
    _emojiController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    // Check if the key event is key press, not key release
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    // Handle arrow keys
    if (arrowKeys[event.logicalKey] != null) {
      // Computing new emoji selection index
      final int newSelectedIndex =
          (_selectedIndex + arrowKeys[event.logicalKey]!)
              .clamp(0, searchEmojiList.length - 1);

      if (newSelectedIndex == _selectedIndex) return KeyEventResult.ignored;

      setState(() => _selectedIndex = newSelectedIndex);
      return KeyEventResult.handled;
    }

    switch (event.logicalKey) {
      case LogicalKeyboardKey.enter:
        _selectEmoji();
        return KeyEventResult.handled;

      case LogicalKeyboardKey.backspace:
        // Delete a character on the editor
        widget.editorState.deleteBackward();
        if (_emojiController.text.isEmpty) {
          widget.onExit();
          return KeyEventResult.handled;
        }

        // Delete a character on the editor
        _emojiController.text = _emojiController.text
            .substring(0, _emojiController.text.length - 1);
        _searchEmoji();
        return KeyEventResult.handled;

      case LogicalKeyboardKey.escape || LogicalKeyboardKey.tab:
        widget.onExit();
        return KeyEventResult.handled;

      default:

        // Determine whether or not the event was from a key with a character
        if (event.character == null) return KeyEventResult.ignored;

        // Typing character
        widget.editorState.insertTextAtCurrentSelection(event.character!);

        // If more than 10 characters have been typed, close menu
        if (_emojiController.text.length > 10) {
          widget.onExit();
          return KeyEventResult.handled;
        }

        // Determine whether or not the shortcut character was pressed again
        if (event.character == widget.shortcutCharacter) {
          widget.onExit();
          return KeyEventResult.handled;
        }

        // Add the character
        _emojiController.text += event.character!;
        _searchEmoji();
        return KeyEventResult.handled;
    }
  }

  void _searchEmoji() {
    // Formatting the emoji search text to increase chances of finding a match
    final String query = _emojiController.text
      ..toLowerCase()
      ..replaceAll(" ", "_");

    searchEmojiList.clear();

    // Search for the emoji in the emoji category groups
    for (int index = 0; index < widget.state.emojiCategoryGroupList.length;) {
      searchEmojiList.addAll(
        widget.state.emojiCategoryGroupList[index].emoji
            .where(
              (item) =>
                  (query.isEmpty || item.name.toLowerCase().contains(query)) &&
                  searchEmojiList.firstWhereOrNull(
                        (emoji) => emoji.name == item.name,
                      ) ==
                      null,
            )
            .take((emojiSearchLimit - searchEmojiList.length) ~/ ++index),
      );
    }
    setState(() {
      _selectedIndex = 0;
    });
  }

  /// Used when an emoji has been selected. This is the final step.
  /// It replaces the typed text used for searching the emoji with the acutal emoji string.
  ///
  void _selectEmoji() async {
    final selection = widget.editorState.selection;
    if (searchEmojiList.isEmpty ||
        selection == null ||
        !selection.isCollapsed) {
      return widget.onExit();
    }

    final node = widget.editorState.getNodeAtPath(selection.end.path);
    if (node == null) {
      return widget.onExit();
    }

    // Replace text with actual emoji
    await widget.editorState.apply(
      widget.editorState.transaction
        ..replaceText(
          node,
          (selection.end.offset - _emojiController.text.length - 1)
              .clamp(0, selection.end.offset),
          selection.end.offset,
          searchEmojiList[_selectedIndex].emoji,
        ),
    );

    // Call function to indicate emoji is selected
    widget.state.onEmojiSelected(
      EmojiCategory.SEARCH,
      searchEmojiList[_selectedIndex],
    );

    widget.onExit();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Focus(
      onKeyEvent: _onKey,
      focusNode: _focusNode,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double emojiSize =
              widget.config.getEmojiSize(constraints.maxWidth);
          return Container(
            padding: const EdgeInsets.all(4.0),
            decoration: BoxDecoration(
              color: widget.config.bgColor,
              borderRadius: Corners.s8Border,
            ),
            // Determine whether or not there are no emojis in search list
            child: Column(
              children: [
                Flexible(
                  child: searchEmojiList.isEmpty
                      ?
                      // If so, display text to indicate that no emoji was found
                      Center(
                          child: Text(
                            widget.config.noEmojiFoundText,
                            style: widget.config.noRecentsStyle,
                            textAlign: TextAlign.center,
                          ),
                        )
                      :
                      // Else, build the emojis' page
                      GridView.builder(
                          cacheExtent: 10,
                          padding: const EdgeInsets.all(0),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: widget.config.emojiNumberPerRow,
                            mainAxisSpacing: widget.config.verticalSpacing,
                            crossAxisSpacing: widget.config.horizontalSpacing,
                          ),
                          itemCount: searchEmojiList.length,
                          itemBuilder: (context, index) => _buildButtonWidget(
                            onPressed: () {
                              setState(() => _selectedIndex = index);
                              _selectEmoji();
                            },
                            child: FlowyHover(
                              resetHoverOnRebuild: false,
                              style: HoverStyle(
                                hoverColor: brightness == Brightness.light
                                    ? null
                                    : Theme.of(context)
                                        .hoverColor
                                        .withAlpha(55),
                              ),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: Corners.s8Border,
                                  color: index == _selectedIndex
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.transparent,
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    searchEmojiList.elementAt(index).emoji,
                                    style: TextStyle(
                                      fontSize: emojiSize,
                                      backgroundColor: Colors.transparent,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildButtonWidget({
    required VoidCallback onPressed,
    required Widget child,
  }) {
    if (widget.config.buttonMode == ButtonMode.MATERIAL) {
      return InkWell(
        onTap: onPressed,
        mouseCursor: SystemMouseCursors.click,
        child: child,
      );
    }
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: child,
      ),
    );
  }
}
