import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/application/field/type_option/relation_type_option_cubit.dart';
import 'package:appflowy/plugins/database/grid/presentation/layout/sizes.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/common/type_option_separator.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
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
            ? const _RelationCellEditorDatabaseList()
            : _RelationCellEditorRowList(
                relatedDatabaseMeta: cellState.relatedDatabaseMeta!,
                selectedRowIds: cellState.rows.map((e) => e.rowId).toList(),
              );
      },
    );
  }
}

class _RelationCellEditorRowList extends StatefulWidget {
  const _RelationCellEditorRowList({
    required this.relatedDatabaseMeta,
    required this.selectedRowIds,
  });

  final DatabaseMeta relatedDatabaseMeta;
  final List<String> selectedRowIds;

  @override
  State<_RelationCellEditorRowList> createState() =>
      _RelationCellEditorRowListState();
}

class _RelationCellEditorRowListState
    extends State<_RelationCellEditorRowList> {
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
        builder: (context, state) {
          return TextFieldTapRegion(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
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
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        child: FlowyText.regular(
                          widget.relatedDatabaseMeta.databaseName,
                          fontSize: 11,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6.0),
                  child: FlowyTextField(
                    focusNode: focusNode,
                    controller: textEditingController,
                    hintText: LocaleKeys
                        .grid_relation_rowSearchTextFieldPlaceholder
                        .tr(),
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
                      final focusedRowId = context
                          .read<RelationRowSearchBloc>()
                          .state
                          .focusedRowId;
                      if (focusedRowId != null) {
                        context
                            .read<RelationCellBloc>()
                            .add(RelationCellEvent.selectRow(focusedRowId));
                      }
                      focusNode.requestFocus();
                    },
                  ),
                ),
                const VSpace(6.0),
                const TypeOptionSeparator(spacing: 0.0),
                if (state.filteredRows.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(6.0) +
                        GridSize.typeOptionContentInsets,
                    child: FlowyText.regular(
                      LocaleKeys.grid_relation_emptySearchResult.tr(),
                      color: Theme.of(context).hintColor,
                    ),
                  )
                else
                  Flexible(
                    child: Focus(
                      descendantsAreFocusable: false,
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        separatorBuilder: (context, index) =>
                            VSpace(GridSize.typeOptionSeparatorHeight),
                        itemCount: state.filteredRows.length,
                        itemBuilder: (context, index) {
                          final row = state.filteredRows[index];
                          return Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 6.0),
                            child: Container(
                              height: 28,
                              decoration: BoxDecoration(
                                color: context
                                            .watch<RelationRowSearchBloc>()
                                            .state
                                            .focusedRowId ==
                                        row.rowId
                                    ? AFThemeExtension.of(context)
                                        .lightGreyHover
                                    : null,
                                borderRadius:
                                    const BorderRadius.all(Radius.circular(6)),
                              ),
                              child: GestureDetector(
                                onTap: () => context
                                    .read<RelationCellBloc>()
                                    .add(
                                      RelationCellEvent.selectRow(row.rowId),
                                    ),
                                child: MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  onHover: (_) =>
                                      context.read<RelationRowSearchBloc>().add(
                                            RelationRowSearchEvent
                                                .updateFocusedOption(row.rowId),
                                          ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6.0,
                                      vertical: 4.0,
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: FlowyText.medium(
                                            row.name.trim().isEmpty
                                                ? LocaleKeys
                                                    .grid_title_placeholder
                                                    .tr()
                                                : row.name,
                                            color: row.name.trim().isEmpty
                                                ? Theme.of(context).hintColor
                                                : null,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (widget.selectedRowIds
                                            .contains(row.rowId))
                                          const FlowySvg(
                                            FlowySvgs.check_s,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
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
}

class _RelationCellEditorDatabaseList extends StatelessWidget {
  const _RelationCellEditorDatabaseList();

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
                        text: FlowyText.medium(
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
