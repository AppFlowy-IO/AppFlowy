import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/application/field/type_option/relation_type_option_cubit.dart';
import 'package:appflowy/plugins/database/grid/presentation/layout/sizes.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/common/type_option_separator.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../application/cell/bloc/relation_cell_bloc.dart';
import '../../application/cell/bloc/relation_row_search_bloc.dart';

class RelationCellEditor extends StatelessWidget {
  const RelationCellEditor({
    super.key,
    required this.selectedRowIds,
  });

  final List<String> selectedRowIds;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RelationCellBloc, RelationCellState>(
      builder: (context, cellState) {
        if (cellState.relatedDatabaseMeta == null) {
          return const _RelationCellEditorDatabaseList();
        }

        return BlocProvider<RelationRowSearchBloc>(
          create: (context) => RelationRowSearchBloc(
            databaseId: cellState.relatedDatabaseMeta!.databaseId,
          ),
          child: BlocBuilder<RelationRowSearchBloc, RelationRowSearchState>(
            builder: (context, state) {
              final children = state.filteredRows
                  .map(
                    (row) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6.0),
                      child: FlowyButton(
                        text: FlowyText.medium(
                          row.name.trim().isEmpty
                              ? LocaleKeys.grid_title_placeholder.tr()
                              : row.name,
                          color: row.name.trim().isEmpty
                              ? Theme.of(context).hintColor
                              : null,
                          overflow: TextOverflow.ellipsis,
                        ),
                        rightIcon: cellState.rows
                                .map((e) => e.rowId)
                                .contains(row.rowId)
                            ? const FlowySvg(
                                FlowySvgs.check_s,
                              )
                            : null,
                        onTap: () => context
                            .read<RelationCellBloc>()
                            .add(RelationCellEvent.selectRow(row.rowId)),
                      ),
                    ),
                  )
                  .toList();

              return Column(
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
                            cellState.relatedDatabaseMeta!.databaseName,
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
                      hintText: LocaleKeys
                          .grid_relation_rowSearchTextFieldPlaceholder
                          .tr(),
                      hintStyle: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Theme.of(context).hintColor),
                      onChanged: (text) => context
                          .read<RelationRowSearchBloc>()
                          .add(RelationRowSearchEvent.updateFilter(text)),
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
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        separatorBuilder: (context, index) =>
                            VSpace(GridSize.typeOptionSeparatorHeight),
                        itemCount: children.length,
                        itemBuilder: (context, index) => children[index],
                      ),
                    ),
                ],
              );
            },
          ),
        );
      },
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
