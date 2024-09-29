import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/application/field/type_option/relation_type_option_cubit.dart';
import 'package:appflowy/plugins/database/grid/presentation/layout/sizes.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/common/type_option_separator.dart';
import 'package:appflowy/plugins/database/tab_bar/tab_bar_view.dart';
import 'package:appflowy/plugins/database/widgets/row/relation_row_detail.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/tabs/tabs_bloc.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../application/cell/bloc/relation_cell_bloc.dart';
import '../../application/cell/bloc/relation_row_search_bloc.dart';

class RelationCellEditor extends StatelessWidget {
  const RelationCellEditor({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RelationCellBloc, RelationCellState>(
      builder: (context, cellState) {
        return cellState.relatedDatabaseMeta == null
            ? const _RelationCellEditorDatabasePicker()
            : _RelationCellEditorContent(
                relatedDatabaseMeta: cellState.relatedDatabaseMeta!,
                selectedRowIds: cellState.rows.map((e) => e.rowId).toList(),
              );
      },
    );
  }
}

class _RelationCellEditorContent extends StatefulWidget {
  const _RelationCellEditorContent({
    required this.relatedDatabaseMeta,
    required this.selectedRowIds,
  });

  final DatabaseMeta relatedDatabaseMeta;
  final List<String> selectedRowIds;

  @override
  State<_RelationCellEditorContent> createState() =>
      _RelationCellEditorContentState();
}

class _RelationCellEditorContentState
    extends State<_RelationCellEditorContent> {
  final textEditingController = TextEditingController();
  late final FocusNode focusNode;
  late final bloc = RelationRowSearchBloc(
    databaseId: widget.relatedDatabaseMeta.databaseId,
  );

  @override
  void initState() {
    super.initState();
    focusNode = FocusNode(
      onKeyEvent: (node, event) {
        switch (event.logicalKey) {
          case LogicalKeyboardKey.arrowUp when event is! KeyUpEvent:
            if (textEditingController.value.composing.isCollapsed) {
              bloc.add(const RelationRowSearchEvent.focusPreviousOption());
              return KeyEventResult.handled;
            }
            break;
          case LogicalKeyboardKey.arrowDown when event is! KeyUpEvent:
            if (textEditingController.value.composing.isCollapsed) {
              bloc.add(const RelationRowSearchEvent.focusNextOption());
              return KeyEventResult.handled;
            }
            break;
          case LogicalKeyboardKey.escape when event is! KeyUpEvent:
            if (!textEditingController.value.composing.isCollapsed) {
              final end = textEditingController.value.composing.end;
              final text = textEditingController.text;

              textEditingController.value = TextEditingValue(
                text: text,
                selection: TextSelection.collapsed(offset: end),
              );
              return KeyEventResult.handled;
            }
            break;
        }
        return KeyEventResult.ignored;
      },
    );
  }

  @override
  void dispose() {
    textEditingController.dispose();
    focusNode.dispose();
    bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: bloc,
      child: BlocBuilder<RelationRowSearchBloc, RelationRowSearchState>(
        buildWhen: (previous, current) =>
            !listEquals(previous.filteredRows, current.filteredRows),
        builder: (context, state) {
          final selected = <RelatedRowDataPB>[];
          final unselected = <RelatedRowDataPB>[];
          for (final row in state.filteredRows) {
            if (widget.selectedRowIds.contains(row.rowId)) {
              selected.add(row);
            } else {
              unselected.add(row);
            }
          }
          return TextFieldTapRegion(
            child: CustomScrollView(
              shrinkWrap: true,
              slivers: [
                _CellEditorTitle(
                  databaseMeta: widget.relatedDatabaseMeta,
                ),
                _SearchField(
                  focusNode: focusNode,
                  textEditingController: textEditingController,
                ),
                const SliverToBoxAdapter(
                  child: TypeOptionSeparator(spacing: 0.0),
                ),
                if (state.filteredRows.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(6.0) +
                          GridSize.typeOptionContentInsets,
                      child: FlowyText.regular(
                        LocaleKeys.grid_relation_emptySearchResult.tr(),
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                  ),
                if (selected.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6.0) +
                          GridSize.typeOptionContentInsets,
                      child: FlowyText.regular(
                        LocaleKeys.grid_relation_linkedRowListLabel.plural(
                          selected.length,
                          namedArgs: {'count': '${selected.length}'},
                        ),
                        fontSize: 11,
                        overflow: TextOverflow.ellipsis,
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                  ),
                  _RowList(
                    databaseId: widget.relatedDatabaseMeta.databaseId,
                    rows: selected,
                    isSelected: true,
                  ),
                  const SliverToBoxAdapter(
                    child: VSpace(4.0),
                  ),
                ],
                if (unselected.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6.0) +
                          GridSize.typeOptionContentInsets,
                      child: FlowyText.regular(
                        LocaleKeys.grid_relation_unlinkedRowListLabel.tr(),
                        fontSize: 11,
                        overflow: TextOverflow.ellipsis,
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                  ),
                  _RowList(
                    databaseId: widget.relatedDatabaseMeta.databaseId,
                    rows: unselected,
                    isSelected: false,
                  ),
                  const SliverToBoxAdapter(
                    child: VSpace(4.0),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CellEditorTitle extends StatelessWidget {
  const _CellEditorTitle({
    required this.databaseMeta,
  });

  final DatabaseMeta databaseMeta;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6.0) +
            GridSize.typeOptionContentInsets,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FlowyText.regular(
              LocaleKeys.grid_relation_inRelatedDatabase.tr(),
              fontSize: 11,
              color: Theme.of(context).hintColor,
            ),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => _openRelatedDatbase(context),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: FlowyText.regular(
                    databaseMeta.databaseName,
                    fontSize: 11,
                    overflow: TextOverflow.ellipsis,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openRelatedDatbase(BuildContext context) {
    FolderEventGetView(ViewIdPB(value: databaseMeta.inlineViewId))
        .send()
        .then((result) {
      result.fold(
        (view) {
          PopoverContainer.of(context).closeAll();
          Navigator.of(context).maybePop();
          getIt<TabsBloc>().add(
            TabsEvent.openPlugin(
              plugin: DatabaseTabBarViewPlugin(
                view: view,
                pluginType: view.pluginType,
              ),
            ),
          );
        },
        (err) => Log.error(err),
      );
    });
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.focusNode,
    required this.textEditingController,
  });

  final FocusNode focusNode;
  final TextEditingController textEditingController;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(left: 6.0, bottom: 6.0, right: 6.0),
        child: FlowyTextField(
          focusNode: focusNode,
          controller: textEditingController,
          hintText: LocaleKeys.grid_relation_rowSearchTextFieldPlaceholder.tr(),
          hintStyle: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Theme.of(context).hintColor),
          onChanged: (text) {
            if (textEditingController.value.composing.isCollapsed) {
              context
                  .read<RelationRowSearchBloc>()
                  .add(RelationRowSearchEvent.updateFilter(text));
            }
          },
          onSubmitted: (_) {
            final focusedRowId =
                context.read<RelationRowSearchBloc>().state.focusedRowId;
            if (focusedRowId != null) {
              final row = context
                  .read<RelationCellBloc>()
                  .state
                  .rows
                  .firstWhereOrNull((e) => e.rowId == focusedRowId);
              if (row != null) {
                FlowyOverlay.show(
                  context: context,
                  builder: (BuildContext overlayContext) {
                    return RelatedRowDetailPage(
                      databaseId: context
                          .read<RelationCellBloc>()
                          .state
                          .relatedDatabaseMeta!
                          .databaseId,
                      rowId: row.rowId,
                    );
                  },
                );
                PopoverContainer.of(context).close();
              } else {
                context
                    .read<RelationCellBloc>()
                    .add(RelationCellEvent.selectRow(focusedRowId));
              }
            }
            focusNode.requestFocus();
          },
        ),
      ),
    );
  }
}

class _RowList extends StatelessWidget {
  const _RowList({
    required this.databaseId,
    required this.rows,
    required this.isSelected,
  });

  final String databaseId;
  final List<RelatedRowDataPB> rows;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => _RowListItem(
          row: rows[index],
          databaseId: databaseId,
          isSelected: isSelected,
        ),
        childCount: rows.length,
      ),
    );
  }
}

class _RowListItem extends StatelessWidget {
  const _RowListItem({
    required this.row,
    required this.isSelected,
    required this.databaseId,
  });

  final RelatedRowDataPB row;
  final String databaseId;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final isHovered =
        context.watch<RelationRowSearchBloc>().state.focusedRowId == row.rowId;
    return Container(
      height: 28,
      margin: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
      decoration: BoxDecoration(
        color: isHovered ? AFThemeExtension.of(context).lightGreyHover : null,
        borderRadius: const BorderRadius.all(Radius.circular(6)),
      ),
      child: GestureDetector(
        onTap: () {
          if (isSelected) {
            FlowyOverlay.show(
              context: context,
              builder: (BuildContext overlayContext) {
                return RelatedRowDetailPage(
                  databaseId: databaseId,
                  rowId: row.rowId,
                );
              },
            );
            PopoverContainer.of(context).close();
          } else {
            context
                .read<RelationCellBloc>()
                .add(RelationCellEvent.selectRow(row.rowId));
          }
        },
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onHover: (_) => context
              .read<RelationRowSearchBloc>()
              .add(RelationRowSearchEvent.updateFocusedOption(row.rowId)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
            child: Row(
              children: [
                Expanded(
                  child: FlowyText(
                    row.name.trim().isEmpty
                        ? LocaleKeys.grid_title_placeholder.tr()
                        : row.name,
                    color: row.name.trim().isEmpty
                        ? Theme.of(context).hintColor
                        : null,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isSelected && isHovered)
                  _UnselectRowButton(
                    onPressed: () => context
                        .read<RelationCellBloc>()
                        .add(RelationCellEvent.selectRow(row.rowId)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UnselectRowButton extends StatefulWidget {
  const _UnselectRowButton({
    required this.onPressed,
  });

  final VoidCallback onPressed;

  @override
  State<_UnselectRowButton> createState() => _UnselectRowButtonState();
}

class _UnselectRowButtonState extends State<_UnselectRowButton> {
  final _materialStatesController = WidgetStatesController();

  @override
  void dispose() {
    _materialStatesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: widget.onPressed,
      onHover: (_) => setState(() {}),
      onFocusChange: (_) => setState(() {}),
      style: ButtonStyle(
        fixedSize: const WidgetStatePropertyAll(Size.square(32)),
        minimumSize: const WidgetStatePropertyAll(Size.square(32)),
        maximumSize: const WidgetStatePropertyAll(Size.square(32)),
        overlayColor: WidgetStateProperty.resolveWith((state) {
          if (state.contains(WidgetState.focused)) {
            return AFThemeExtension.of(context).greyHover;
          }
          return Colors.transparent;
        }),
        shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: Corners.s6Border),
        ),
      ),
      statesController: _materialStatesController,
      child: Container(
        color: _materialStatesController.value.contains(WidgetState.hovered) ||
                _materialStatesController.value.contains(WidgetState.focused)
            ? Theme.of(context).colorScheme.primary
            : AFThemeExtension.of(context).onBackground,
        width: 12,
        height: 1,
      ),
    );
  }
}

class _RelationCellEditorDatabasePicker extends StatelessWidget {
  const _RelationCellEditorDatabasePicker();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => RelationDatabaseListCubit(),
      child: BlocBuilder<RelationDatabaseListCubit, RelationDatabaseListState>(
        builder: (context, state) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 6, 6, 0),
                child: FlowyText(
                  LocaleKeys.grid_relation_noDatabaseSelected.tr(),
                  maxLines: null,
                  fontSize: 10,
                  color: Theme.of(context).hintColor,
                ),
              ),
              Flexible(
                child: ListView.separated(
                  padding: const EdgeInsets.all(6),
                  separatorBuilder: (context, index) =>
                      VSpace(GridSize.typeOptionSeparatorHeight),
                  itemCount: state.databaseMetas.length,
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    final databaseMeta = state.databaseMetas[index];
                    return SizedBox(
                      height: GridSize.popoverItemHeight,
                      child: FlowyButton(
                        onTap: () => context.read<RelationCellBloc>().add(
                              RelationCellEvent.selectDatabaseId(
                                databaseMeta.databaseId,
                              ),
                            ),
                        text: FlowyText(
                          databaseMeta.databaseName,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
