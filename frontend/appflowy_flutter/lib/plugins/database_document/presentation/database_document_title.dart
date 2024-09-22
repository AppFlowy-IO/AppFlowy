import 'package:flutter/material.dart';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/application/cell/bloc/text_cell_bloc.dart';
import 'package:appflowy/plugins/database/application/cell/cell_controller.dart';
import 'package:appflowy/plugins/database/widgets/cell/editable_cell_builder.dart';
import 'package:appflowy/plugins/database/widgets/cell/editable_cell_skeleton/text.dart';
import 'package:appflowy/plugins/database/widgets/row/cells/cell_container.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/base/emoji_picker_button.dart';
import 'package:appflowy/workspace/presentation/widgets/view_title_bar.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'database_document_title_bloc.dart';

// This widget is largely copied from `workspace/presentation/widgets/view_title_bar.dart` intentionally instead of opting for an abstraction. We can make an abstraction after the view refactor is done and there's more clarity in that department.

// workspaces / ... / database view name / row name
class ViewTitleBarWithRow extends StatelessWidget {
  const ViewTitleBarWithRow({
    super.key,
    required this.view,
    required this.databaseId,
    required this.rowId,
  });

  final ViewPB view;
  final String databaseId;
  final String rowId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DatabaseDocumentTitleBloc(
        view: view,
        rowId: rowId,
      ),
      child: BlocBuilder<DatabaseDocumentTitleBloc, DatabaseDocumentTitleState>(
        builder: (context, state) {
          if (state.ancestors.isEmpty) {
            return const SizedBox.shrink();
          }
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              height: 24,
              child: Row(
                // refresh the view title bar when the ancestors changed
                key: ValueKey(state.ancestors.hashCode),
                children: _buildViewTitles(state.ancestors),
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildViewTitles(List<ViewPB> views) {
    // if the level is too deep, only show the root view, the database view and the row
    return views.length > 2
        ? [
            _buildViewButton(views[1]),
            const FlowySvg(FlowySvgs.title_bar_divider_s),
            const FlowyText.regular(' ... '),
            const FlowySvg(FlowySvgs.title_bar_divider_s),
            _buildViewButton(views.last),
            const FlowySvg(FlowySvgs.title_bar_divider_s),
            _buildRowName(),
          ]
        : [
            ...views
                .map(
                  (e) => [
                    _buildViewButton(e),
                    const FlowySvg(FlowySvgs.title_bar_divider_s),
                  ],
                )
                .flattened,
            _buildRowName(),
          ];
  }

  Widget _buildViewButton(ViewPB view) {
    return FlowyTooltip(
      message: view.name,
      child: ViewTitle(
        view: view,
        behavior: ViewTitleBehavior.uneditable,
        onUpdated: () {},
      ),
    );
  }

  Widget _buildRowName() {
    return _RowName(
      rowId: rowId,
    );
  }
}

class _RowName extends StatelessWidget {
  const _RowName({
    required this.rowId,
  });

  final String rowId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DatabaseDocumentTitleBloc, DatabaseDocumentTitleState>(
      builder: (context, state) {
        if (state.databaseController == null) {
          return const SizedBox.shrink();
        }

        final cellBuilder = EditableCellBuilder(
          databaseController: state.databaseController!,
        );

        return cellBuilder.buildCustom(
          CellContext(
            fieldId: state.fieldId!,
            rowId: rowId,
          ),
          skinMap: EditableCellSkinMap(textSkin: _TitleSkin()),
        );
      },
    );
  }
}

class _TitleSkin extends IEditableTextCellSkin {
  @override
  Widget build(
    BuildContext context,
    CellContainerNotifier cellContainerNotifier,
    TextCellBloc bloc,
    FocusNode focusNode,
    TextEditingController textEditingController,
  ) {
    return BlocSelector<TextCellBloc, TextCellState, String>(
      selector: (state) => state.content ?? "",
      builder: (context, content) {
        final name = content.isEmpty
            ? LocaleKeys.grid_row_titlePlaceholder.tr()
            : content;
        return BlocBuilder<DatabaseDocumentTitleBloc,
            DatabaseDocumentTitleState>(
          builder: (context, state) {
            return FlowyTooltip(
              message: name,
              child: AppFlowyPopover(
                constraints: const BoxConstraints(
                  maxWidth: 300,
                  maxHeight: 44,
                ),
                direction: PopoverDirection.bottomWithLeftAligned,
                offset: const Offset(0, 18),
                popupBuilder: (_) {
                  return RenameRowPopover(
                    textController: textEditingController,
                    icon: state.icon ?? "",
                    onUpdateIcon: (String icon) {
                      context
                          .read<DatabaseDocumentTitleBloc>()
                          .add(DatabaseDocumentTitleEvent.updateIcon(icon));
                    },
                    onUpdateName: (text) =>
                        bloc.add(TextCellEvent.updateText(text)),
                  );
                },
                child: FlowyButton(
                  useIntrinsicWidth: true,
                  onTap: () {},
                  text: Row(
                    children: [
                      if (state.icon != null) ...[
                        FlowyText.emoji(
                          state.icon!,
                          fontSize: 14.0,
                          figmaLineHeight: 18.0,
                        ),
                        const HSpace(4.0),
                      ],
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 180),
                        child: FlowyText.regular(
                          name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class RenameRowPopover extends StatefulWidget {
  const RenameRowPopover({
    super.key,
    required this.textController,
    required this.onUpdateName,
    required this.onUpdateIcon,
    required this.icon,
  });

  final TextEditingController textController;
  final String icon;

  final void Function(String name) onUpdateName;
  final void Function(String icon) onUpdateIcon;

  @override
  State<RenameRowPopover> createState() => _RenameRowPopoverState();
}

class _RenameRowPopoverState extends State<RenameRowPopover> {
  @override
  void initState() {
    super.initState();
    widget.textController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: widget.textController.value.text.characters.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        EmojiPickerButton(
          emoji: widget.icon,
          direction: PopoverDirection.bottomWithCenterAligned,
          offset: const Offset(0, 18),
          defaultIcon: const FlowySvg(FlowySvgs.document_s),
          onSubmitted: (emoji, _) {
            widget.onUpdateIcon(emoji);
            PopoverContainer.of(context).close();
          },
        ),
        const HSpace(6),
        SizedBox(
          height: 36.0,
          width: 220,
          child: FlowyTextField(
            controller: widget.textController,
            maxLength: 256,
            onSubmitted: (text) {
              widget.onUpdateName(text);
              PopoverContainer.of(context).close();
            },
            onCanceled: () => widget.onUpdateName(widget.textController.text),
            showCounter: false,
          ),
        ),
      ],
    );
  }
}
