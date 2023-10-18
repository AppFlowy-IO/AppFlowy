import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/database_view/board/application/board_bloc.dart';
import 'package:appflowy/plugins/database_view/widgets/card/define.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pbenum.dart';
import 'package:appflowy_board/appflowy_board.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BoardColumnHeader extends StatefulWidget {
  const BoardColumnHeader({
    super.key,
    required this.groupData,
    this.margin,
  });

  final AppFlowyGroupData groupData;
  final EdgeInsets? margin;

  @override
  State<BoardColumnHeader> createState() => _BoardColumnHeaderState();
}

class _BoardColumnHeaderState extends State<BoardColumnHeader> {
  final FocusNode _focusNode = FocusNode();

  late final TextEditingController _controller =
      TextEditingController.fromValue(
    TextEditingValue(
      selection: TextSelection.collapsed(
        offset: widget.groupData.headerData.groupName.length,
      ),
      text: widget.groupData.headerData.groupName,
    ),
  );

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        _saveEdit();
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final boardCustomData = widget.groupData.customData as GroupData;

    return BlocProvider<BoardBloc>.value(
      value: context.read<BoardBloc>(),
      child: BlocBuilder<BoardBloc, BoardState>(
        builder: (context, state) {
          Widget title = Flexible(
            fit: FlexFit.tight,
            child: GestureDetector(
              onTap: () => context
                  .read<BoardBloc>()
                  .add(BoardEvent.startEditingHeader(widget.groupData.id)),
              child: FlowyText.medium(
                widget.groupData.headerData.groupName,
                fontSize: 14,
                overflow: TextOverflow.clip,
              ),
            ),
          );

          if (state.isEditingHeader &&
              state.editingHeaderId == widget.groupData.id) {
            title = _buildTextField(context);
            // _focusNode.requestFocus();
          }

          return AppFlowyGroupHeader(
            title: title,
            icon: _buildHeaderIcon(boardCustomData),
            addIcon: SizedBox(
              height: 20,
              width: 20,
              child: FlowySvg(
                FlowySvgs.add_s,
                color: Theme.of(context).iconTheme.color,
              ),
            ),
            onAddButtonClick: () => context
                .read<BoardBloc>()
                .add(BoardEvent.createHeaderRow(widget.groupData.id)),
            height: 50,
            margin: widget.margin ?? EdgeInsets.zero,
          );
        },
      ),
    );
  }

  Widget _buildTextField(BuildContext context) {
    return Expanded(
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        // onChanged: (value) => focusChanged(),
        onEditingComplete: _saveEdit,
        maxLines: null,
        style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontSize: 14),
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

  void _saveEdit() {
    context.read<BoardBloc>().add(
          BoardEvent.endEditingHeader(
            widget.groupData.id,
            _controller.text,
          ),
        );
  }
}

Widget? _buildHeaderIcon(GroupData customData) {
  Widget? widget;
  switch (customData.fieldType) {
    case FieldType.Checkbox:
      final group = customData.asCheckboxGroup()!;
      widget = FlowySvg(
        group.isCheck ? FlowySvgs.check_filled_s : FlowySvgs.uncheck_s,
        blendMode: BlendMode.dst,
      );
      break;
    case FieldType.DateTime:
    case FieldType.LastEditedTime:
    case FieldType.CreatedTime:
    case FieldType.MultiSelect:
    case FieldType.Number:
    case FieldType.RichText:
    case FieldType.SingleSelect:
    case FieldType.URL:
    case FieldType.Checklist:
      break;
  }

  if (widget != null) {
    widget = SizedBox(
      width: 20,
      height: 20,
      child: widget,
    );
  }

  return null;
}
