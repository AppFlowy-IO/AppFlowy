import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/base/emoji/emoji_text.dart';
import 'package:appflowy/plugins/database/application/cell/bloc/text_cell_bloc.dart';
import 'package:appflowy/plugins/database/application/cell/cell_controller.dart';
import 'package:appflowy/plugins/database/widgets/cell/editable_cell_builder.dart';
import 'package:appflowy/plugins/database/widgets/cell/editable_cell_skeleton/text.dart';
import 'package:appflowy/plugins/database/widgets/row/cells/cell_container.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/base/emoji_picker_button.dart';
import 'package:appflowy/startup/tasks/app_window_size_manager.dart';
import 'package:appflowy/workspace/application/tabs/tabs_bloc.dart';
import 'package:appflowy/workspace/application/view/view_listener.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/widget/flowy_tooltip.dart';
import 'package:flutter/material.dart';
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
          const maxWidth = WindowSizeManager.minWindowWidth - 200;
          return LayoutBuilder(
            builder: (context, constraints) {
              return Visibility(
                visible: maxWidth < constraints.maxWidth,
                // if the width is too small, only show one view title bar without the ancestors
                replacement: _ViewTitle(
                  key: ValueKey(state.ancestors.last),
                  view: state.ancestors.last,
                  maxTitleWidth: constraints.maxWidth - 50.0,
                  onUpdated: () {},
                ),
                child: Row(
                  // refresh the view title bar when the ancestors changed
                  key: ValueKey(state.ancestors.hashCode),
                  children: _buildViewTitles(state.ancestors),
                ),
              );
            },
          );
        },
      ),
    );
  }

  List<Widget> _buildViewTitles(List<ViewPB> views) {
    // if the level is too deep, only show the root view, the database view and the row
    return views.length > 2
        ? [
            _buildViewButton(views.first),
            const FlowyText.regular('/'),
            const FlowyText.regular(' ... /'),
            _buildViewButton(views.last),
            const FlowyText.regular('/'),
            _buildRowName(),
          ]
        : [
            ...views
                .map((e) => [_buildViewButton(e), const FlowyText.regular('/')])
                .flattened,
            _buildRowName(),
          ];
  }

  Widget _buildViewButton(ViewPB view) {
    return FlowyTooltip(
      message: view.name,
      child: _ViewTitle(
        view: view,
        behavior: _ViewTitleBehavior.uneditable,
        onUpdated: () {},
      ),
    );
  }

  Widget _buildRowName() {
    return BlocBuilder<DatabaseDocumentTitleBloc, DatabaseDocumentTitleState>(
      builder: (context, state) {
        if (state.databaseController == null) {
          return const SizedBox.shrink();
        }
        return _RowName(
          cellBuilder: EditableCellBuilder(
            databaseController: state.databaseController!,
          ),
          primaryFieldId: state.fieldId!,
          rowId: rowId,
        );
      },
    );
  }
}

class _RowName extends StatelessWidget {
  const _RowName({
    required this.cellBuilder,
    required this.primaryFieldId,
    required this.rowId,
  });

  final EditableCellBuilder cellBuilder;
  final String primaryFieldId;
  final String rowId;

  @override
  Widget build(BuildContext context) {
    return cellBuilder.buildCustom(
      CellContext(
        fieldId: primaryFieldId,
        rowId: rowId,
      ),
      skinMap: EditableCellSkinMap(textSkin: _TitleSkin()),
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
      selector: (state) => state.content,
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
                      EmojiText(
                        emoji: state.icon ?? "",
                        fontSize: 18.0,
                      ),
                      const HSpace(2.0),
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

enum _ViewTitleBehavior {
  editable,
  uneditable,
}

class _ViewTitle extends StatefulWidget {
  const _ViewTitle({
    super.key,
    required this.view,
    this.behavior = _ViewTitleBehavior.editable,
    this.maxTitleWidth = 180,
    required this.onUpdated,
  });

  final ViewPB view;
  final _ViewTitleBehavior behavior;
  final double maxTitleWidth;
  final VoidCallback onUpdated;

  @override
  State<_ViewTitle> createState() => _ViewTitleState();
}

class _ViewTitleState extends State<_ViewTitle> {
  late final viewListener = ViewListener(viewId: widget.view.id);

  String name = '';
  String icon = '';

  @override
  void initState() {
    super.initState();

    name = widget.view.name.isEmpty
        ? LocaleKeys.document_title_placeholder.tr()
        : widget.view.name;
    icon = widget.view.icon.value;

    viewListener.start(
      onViewUpdated: (view) {
        if (name != view.name || icon != view.icon.value) {
          widget.onUpdated();
        }
        setState(() {
          name = view.name.isEmpty
              ? LocaleKeys.document_title_placeholder.tr()
              : view.name;
          icon = view.icon.value;
        });
      },
    );
  }

  @override
  void dispose() {
    viewListener.stop();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // root view
    if (widget.view.parentViewId.isEmpty) {
      return Row(
        children: [
          FlowyText.regular(name),
          const HSpace(4.0),
        ],
      );
    }

    final child = Row(
      children: [
        EmojiText(
          emoji: icon,
          fontSize: 18.0,
        ),
        const HSpace(2.0),
        ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: widget.maxTitleWidth,
          ),
          child: FlowyText.regular(
            name,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    return Listener(
      onPointerDown: (_) => context.read<TabsBloc>().openPlugin(widget.view),
      child: FlowyButton(
        useIntrinsicWidth: true,
        onTap: () {},
        text: child,
      ),
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
