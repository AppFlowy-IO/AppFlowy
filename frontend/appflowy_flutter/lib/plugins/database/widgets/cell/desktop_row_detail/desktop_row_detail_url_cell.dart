import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/widgets/cell/desktop_grid/desktop_grid_url_cell.dart';
import 'package:appflowy/plugins/database/widgets/row/accessory/cell_accessory.dart';
import 'package:appflowy/plugins/database/widgets/row/cells/cell_container.dart';
import 'package:appflowy/plugins/database/application/cell/bloc/url_cell_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../editable_cell_skeleton/url.dart';

class DesktopRowDetailURLSkin extends IEditableURLCellSkin {
  @override
  Widget build(
    BuildContext context,
    CellContainerNotifier cellContainerNotifier,
    URLCellBloc bloc,
    FocusNode focusNode,
    TextEditingController textEditingController,
    URLCellDataNotifier cellDataNotifier,
  ) {
    return LinkTextField(
      controller: textEditingController,
      focusNode: focusNode,
    );
  }

  @override
  List<GridCellAccessoryBuilder> accessoryBuilder(
    GridCellAccessoryBuildContext context,
    URLCellDataNotifier cellDataNotifier,
  ) {
    return [
      accessoryFromType(
        GridURLCellAccessoryType.visitURL,
        cellDataNotifier,
      ),
    ];
  }
}

class LinkTextField extends StatefulWidget {
  const LinkTextField({
    super.key,
    required this.controller,
    required this.focusNode,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  @override
  State<LinkTextField> createState() => _LinkTextFieldState();
}

class _LinkTextFieldState extends State<LinkTextField> {
  bool _isLinkClickable = false;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleGlobalKeyEvent);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleGlobalKeyEvent);
    super.dispose();
  }

  bool _handleGlobalKeyEvent(KeyEvent event) {
    setState(() {
      _isLinkClickable = event is KeyDownEvent &&
          [
            LogicalKeyboardKey.control,
            LogicalKeyboardKey.controlLeft,
            LogicalKeyboardKey.controlRight,
            LogicalKeyboardKey.meta,
            LogicalKeyboardKey.metaLeft,
            LogicalKeyboardKey.metaRight,
          ].contains(event.logicalKey);
    });

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      mouseCursor:
          _isLinkClickable ? SystemMouseCursors.click : SystemMouseCursors.text,
      controller: widget.controller,
      focusNode: widget.focusNode,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            decoration: TextDecoration.underline,
          ),
      onTap: () {
        if (_isLinkClickable) {
          openUrlCellLink(widget.controller.text);
        }
      },
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
        border: InputBorder.none,
        focusedBorder: InputBorder.none,
        enabledBorder: InputBorder.none,
        errorBorder: InputBorder.none,
        disabledBorder: InputBorder.none,
        hintText: LocaleKeys.grid_row_textPlaceholder.tr(),
        hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).hintColor,
            ),
        isDense: true,
      ),
    );
  }
}
