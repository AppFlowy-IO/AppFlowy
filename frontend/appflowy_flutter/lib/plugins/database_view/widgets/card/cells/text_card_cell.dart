import 'package:appflowy/plugins/database_view/application/cell/cell_controller_builder.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../row/cell_builder.dart';
import '../bloc/text_card_cell_bloc.dart';
import '../define.dart';
import 'card_cell.dart';

class TextCardCellStyle extends CardCellStyle {
  final double fontSize;

  TextCardCellStyle(this.fontSize);
}

class TextCardCell<CustomCardData>
    extends CardCell<CustomCardData, TextCardCellStyle> with EditableCell {
  @override
  final EditableCardNotifier? editableNotifier;
  final CellControllerBuilder cellControllerBuilder;
  final CellRenderHook<String, CustomCardData>? renderHook;

  const TextCardCell({
    required this.cellControllerBuilder,
    required CustomCardData? cardData,
    this.editableNotifier,
    this.renderHook,
    TextCardCellStyle? style,
    Key? key,
  }) : super(key: key, style: style, cardData: cardData);

  @override
  State<TextCardCell> createState() => _TextCardCellState();
}

class _TextCardCellState extends State<TextCardCell> {
  late TextCardCellBloc _cellBloc;
  late TextEditingController _controller;
  bool focusWhenInit = false;
  final focusNode = SingleListenerFocusNode();

  @override
  void initState() {
    final cellController =
        widget.cellControllerBuilder.build() as TextCellController;
    _cellBloc = TextCardCellBloc(cellController: cellController)
      ..add(const TextCardCellEvent.initial());
    _controller = TextEditingController(text: _cellBloc.state.content);
    focusWhenInit = widget.editableNotifier?.isCellEditing.value ?? false;
    if (focusWhenInit) {
      focusNode.requestFocus();
    }

    // If the focusNode lost its focus, the widget's editableNotifier will
    // set to false, which will cause the [EditableRowNotifier] to receive
    // end edit event.
    focusNode.addListener(() {
      if (!focusNode.hasFocus) {
        focusWhenInit = false;
        widget.editableNotifier?.isCellEditing.value = false;
        _cellBloc.add(const TextCardCellEvent.enableEdit(false));
      }
    });
    _bindEditableNotifier();
    super.initState();
  }

  void _bindEditableNotifier() {
    widget.editableNotifier?.isCellEditing.addListener(() {
      if (!mounted) return;

      final isEditing = widget.editableNotifier?.isCellEditing.value ?? false;
      if (isEditing) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          focusNode.requestFocus();
        });
      }
      _cellBloc.add(TextCardCellEvent.enableEdit(isEditing));
    });
  }

  @override
  void didUpdateWidget(covariant TextCardCell oldWidget) {
    _bindEditableNotifier();
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cellBloc,
      child: BlocListener<TextCardCellBloc, TextCardCellState>(
        listener: (context, state) {
          if (_controller.text != state.content) {
            _controller.text = state.content;
          }
        },
        child: BlocBuilder<TextCardCellBloc, TextCardCellState>(
          buildWhen: (previous, current) {
            if (previous.content != current.content &&
                _controller.text == current.content &&
                current.enableEdit) {
              return false;
            }

            return previous != current;
          },
          builder: (context, state) {
            // Returns a custom render widget
            final Widget? custom = widget.renderHook?.call(
              state.content,
              widget.cardData,
              context,
            );
            if (custom != null) {
              return custom;
            }

            if (state.content.isEmpty &&
                state.enableEdit == false &&
                focusWhenInit == false) {
              return const SizedBox();
            }

            //
            Widget child;
            if (state.enableEdit || focusWhenInit) {
              child = _buildTextField();
            } else {
              child = _buildText(state);
            }
            return Align(alignment: Alignment.centerLeft, child: child);
          },
        ),
      ),
    );
  }

  Future<void> focusChanged() async {
    _cellBloc.add(TextCardCellEvent.updateText(_controller.text));
  }

  @override
  Future<void> dispose() async {
    _cellBloc.close();
    _controller.dispose();
    focusNode.dispose();
    super.dispose();
  }

  double _fontSize() {
    if (widget.style != null) {
      return widget.style!.fontSize;
    } else {
      return 14;
    }
  }

  Widget _buildText(TextCardCellState state) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: CardSizes.cardCellVPadding,
      ),
      child: FlowyText.medium(
        state.content,
        fontSize: _fontSize(),
        maxLines: null, // Enable multiple lines
      ),
    );
  }

  Widget _buildTextField() {
    return IntrinsicHeight(
      child: TextField(
        controller: _controller,
        focusNode: focusNode,
        onChanged: (value) => focusChanged(),
        onEditingComplete: () => focusNode.unfocus(),
        maxLines: null,
        style: Theme.of(context)
            .textTheme
            .bodyMedium!
            .copyWith(fontSize: _fontSize()),
        decoration: InputDecoration(
          // Magic number 4 makes the textField take up the same space as FlowyText
          contentPadding: EdgeInsets.symmetric(
            vertical: CardSizes.cardCellVPadding + 4,
          ),
          border: InputBorder.none,
          isDense: true,
        ),
      ),
    );
  }
}
