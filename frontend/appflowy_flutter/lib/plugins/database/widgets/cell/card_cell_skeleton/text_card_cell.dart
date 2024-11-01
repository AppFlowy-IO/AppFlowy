import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/application/cell/bloc/text_cell_bloc.dart';
import 'package:appflowy/plugins/database/application/cell/cell_controller.dart';
import 'package:appflowy/plugins/database/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database/application/database_controller.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../editable_cell_builder.dart';
import 'card_cell.dart';

class TextCardCellStyle extends CardCellStyle {
  TextCardCellStyle({
    required super.padding,
    required this.textStyle,
    required this.titleTextStyle,
    this.maxLines = 1,
  });

  final TextStyle textStyle;
  final TextStyle titleTextStyle;
  final int? maxLines;
}

class TextCardCell extends CardCell<TextCardCellStyle> with EditableCell {
  const TextCardCell({
    super.key,
    required super.style,
    required this.databaseController,
    required this.cellContext,
    this.showNotes = false,
    this.editableNotifier,
  });

  final DatabaseController databaseController;
  final CellContext cellContext;
  final bool showNotes;

  @override
  final EditableCardNotifier? editableNotifier;

  @override
  State<TextCardCell> createState() => _TextCellState();
}

class _TextCellState extends State<TextCardCell> {
  late final cellBloc = TextCellBloc(
    cellController: makeCellController(
      widget.databaseController,
      widget.cellContext,
    ).as(),
  );
  late final TextEditingController _textEditingController;
  final focusNode = SingleListenerFocusNode();

  @override
  void initState() {
    super.initState();
    _textEditingController =
        TextEditingController(text: cellBloc.state.content);

    if (widget.editableNotifier?.isCellEditing.value ?? false) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        focusNode.requestFocus();
        cellBloc.add(const TextCellEvent.enableEdit(true));
      });
    }

    // If the focusNode lost its focus, the widget's editableNotifier will
    // set to false, which will cause the [EditableRowNotifier] to receive
    // end edit event.
    focusNode.addListener(_onFocusChanged);
    _bindEditableNotifier();
  }

  void _onFocusChanged() {
    if (!focusNode.hasFocus) {
      widget.editableNotifier?.isCellEditing.value = false;
      cellBloc.add(const TextCellEvent.enableEdit(false));
      cellBloc.add(TextCellEvent.updateText(_textEditingController.text));
    }
  }

  void _bindEditableNotifier() {
    widget.editableNotifier?.isCellEditing.addListener(() {
      if (!mounted) {
        return;
      }

      final isEditing = widget.editableNotifier?.isCellEditing.value ?? false;
      if (isEditing) {
        WidgetsBinding.instance
            .addPostFrameCallback((_) => focusNode.requestFocus());
      }
      cellBloc.add(TextCellEvent.enableEdit(isEditing));
    });
  }

  @override
  void didUpdateWidget(covariant oldWidget) {
    if (oldWidget.editableNotifier != widget.editableNotifier) {
      _bindEditableNotifier();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    final isTitle = cellBloc.cellController.fieldInfo.isPrimary;
    return BlocProvider.value(
      value: cellBloc,
      child: BlocListener<TextCellBloc, TextCellState>(
        listenWhen: (previous, current) => previous.content != current.content,
        listener: (context, state) {
          _textEditingController.text = state.content ?? "";
        },
        child: isTitle ? _buildTitle() : _buildText(),
      ),
    );
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    widget.editableNotifier?.isCellEditing
        .removeListener(_bindEditableNotifier);
    focusNode.dispose();
    cellBloc.close();
    super.dispose();
  }

  Widget? _buildIcon(TextCellState state) {
    if (state.emoji?.value.isNotEmpty ?? false) {
      return FlowyText.emoji(
        optimizeEmojiAlign: true,
        state.emoji?.value ?? '',
      );
    }

    if (widget.showNotes) {
      return FlowyTooltip(
        message: LocaleKeys.board_notesTooltip.tr(),
        child: FlowySvg(
          FlowySvgs.notes_s,
          color: Theme.of(context).hintColor,
        ),
      );
    }
    return null;
  }

  Widget _buildText() {
    return BlocBuilder<TextCellBloc, TextCellState>(
      builder: (context, state) {
        final content = state.content ?? "";

        return content.isEmpty
            ? const SizedBox.shrink()
            : Container(
                padding: widget.style.padding,
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  content,
                  style: widget.style.textStyle,
                  maxLines: widget.style.maxLines,
                ),
              );
      },
    );
  }

  Widget _buildTitle() {
    final textField = _buildTextField();
    return BlocBuilder<TextCellBloc, TextCellState>(
      builder: (context, state) {
        final icon = _buildIcon(state);
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null) ...[
              icon,
              const HSpace(4.0),
            ],
            Expanded(child: textField),
          ],
        );
      },
    );
  }

  Widget _buildTextField() {
    return BlocSelector<TextCellBloc, TextCellState, bool>(
      selector: (state) => state.enableEdit,
      builder: (context, isEditing) {
        return IgnorePointer(
          ignoring: !isEditing,
          child: CallbackShortcuts(
            bindings: {
              const SingleActivator(LogicalKeyboardKey.escape): () =>
                  focusNode.unfocus(),
              const SimpleActivator(LogicalKeyboardKey.enter): () =>
                  focusNode.unfocus(),
            },
            child: TextField(
              controller: _textEditingController,
              focusNode: focusNode,
              onEditingComplete: () => focusNode.unfocus(),
              onSubmitted: (_) => focusNode.unfocus(),
              maxLines: null,
              minLines: 1,
              textInputAction: TextInputAction.done,
              readOnly: !isEditing,
              enableInteractiveSelection: isEditing,
              style: widget.style.titleTextStyle,
              decoration: InputDecoration(
                contentPadding: widget.style.padding,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                isDense: true,
                isCollapsed: true,
                hintText: LocaleKeys.grid_row_titlePlaceholder.tr(),
                hintStyle: widget.style.titleTextStyle.copyWith(
                  color: Theme.of(context).hintColor,
                ),
              ),
              onTapOutside: (_) {},
            ),
          ),
        );
      },
    );
  }
}

class SimpleActivator with Diagnosticable implements ShortcutActivator {
  const SimpleActivator(
    this.trigger, {
    this.includeRepeats = true,
  });

  final LogicalKeyboardKey trigger;
  final bool includeRepeats;

  @override
  bool accepts(KeyEvent event, HardwareKeyboard state) {
    return (event is KeyDownEvent ||
            (includeRepeats && event is KeyRepeatEvent)) &&
        trigger == event.logicalKey;
  }

  @override
  String debugDescribeKeys() =>
      kDebugMode ? trigger.debugName ?? trigger.toStringShort() : '';

  @override
  Iterable<LogicalKeyboardKey>? get triggers => <LogicalKeyboardKey>[trigger];
}
