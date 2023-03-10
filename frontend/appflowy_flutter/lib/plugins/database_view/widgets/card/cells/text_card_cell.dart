import 'package:appflowy/plugins/database_view/application/cell/cell_controller_builder.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:textstyle_extensions/textstyle_extensions.dart';
import '../../row/cell_builder.dart';
import '../bloc/text_card_cell_bloc.dart';
import '../define.dart';
import 'card_cell.dart';

class TextCardCell extends CardCell with EditableCell {
  @override
  final EditableCardNotifier? editableNotifier;
  final CellControllerBuilder cellControllerBuilder;

  const TextCardCell({
    required this.cellControllerBuilder,
    this.editableNotifier,
    Key? key,
  }) : super(key: key);

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

  Widget _buildText(TextCardCellState state) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: CardSizes.cardCellVPadding,
      ),
      child: FlowyText.medium(
        state.content,
        fontSize: 14,
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
        style: Theme.of(context).textTheme.bodyMedium!.size(FontSizes.s14),
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
