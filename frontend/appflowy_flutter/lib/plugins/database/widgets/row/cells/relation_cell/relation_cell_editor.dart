import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/grid/presentation/layout/sizes.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/common/type_option_separator.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'relation_cell_bloc.dart';
import 'relation_row_search_bloc.dart';

class RelationCellEditor extends StatelessWidget {
  const RelationCellEditor({
    super.key,
    required this.databaseId,
    required this.selectedRowIds,
    required this.onSelectRow,
  });

  final String databaseId;
  final List<String> selectedRowIds;
  final void Function(String rowId) onSelectRow;

  @override
  Widget build(BuildContext context) {
    if (databaseId.isEmpty) {
      // no i18n here because UX needs thorough checking.
      return const Center(
        child: FlowyText(
          '''
No database has been selected,
please select one first in the field editor.
          ''',
          maxLines: null,
          textAlign: TextAlign.center,
        ),
      );
    }

    return BlocProvider<RelationRowSearchBloc>(
      create: (context) => RelationRowSearchBloc(
        databaseId: databaseId,
      ),
      child: BlocBuilder<RelationCellBloc, RelationCellState>(
        builder: (context, cellState) {
          return BlocBuilder<RelationRowSearchBloc, RelationRowSearchState>(
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
                            ? FlowySvg(
                                FlowySvgs.check_s,
                                color: Theme.of(context).primaryColor,
                              )
                            : null,
                        onTap: () => onSelectRow(row.rowId),
                      ),
                    ),
                  )
                  .toList();

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const VSpace(6.0),
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
                        const HSpace(2.0),
                        FlowyButton(
                          useIntrinsicWidth: true,
                          margin: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          text: FlowyText.regular(
                            cellState.relatedDatabaseId,
                            fontSize: 11,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  VSpace(GridSize.typeOptionSeparatorHeight),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6.0),
                    child: FlowyTextField(
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
                        "No records found",
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
          );
        },
      ),
    );
  }
}
