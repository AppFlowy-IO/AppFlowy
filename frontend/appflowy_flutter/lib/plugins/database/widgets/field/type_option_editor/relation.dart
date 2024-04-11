import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/application/field/type_option/relation_type_option_cubit.dart';
import 'package:appflowy/plugins/database/application/field/type_option/type_option_data_parser.dart';
import 'package:appflowy/plugins/database/grid/presentation/layout/sizes.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:protobuf/protobuf.dart';

import 'builder.dart';

class RelationTypeOptionEditorFactory implements TypeOptionEditorFactory {
  const RelationTypeOptionEditorFactory();

  @override
  Widget? build({
    required BuildContext context,
    required String viewId,
    required FieldPB field,
    required PopoverMutex popoverMutex,
    required TypeOptionDataCallback onTypeOptionUpdated,
  }) {
    final typeOption = _parseTypeOptionData(field.typeOptionData);

    return BlocProvider(
      create: (_) => RelationDatabaseListCubit(),
      child: Builder(
        builder: (context) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.only(left: 14, right: 8),
                height: GridSize.popoverItemHeight,
                alignment: Alignment.centerLeft,
                child: FlowyText.regular(
                  LocaleKeys.grid_relation_relatedDatabasePlaceLabel.tr(),
                  color: Theme.of(context).hintColor,
                  fontSize: 11,
                ),
              ),
              AppFlowyPopover(
                mutex: popoverMutex,
                triggerActions:
                    PopoverTriggerFlags.hover | PopoverTriggerFlags.click,
                offset: const Offset(6, 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  height: GridSize.popoverItemHeight,
                  child: FlowyButton(
                    text: BlocBuilder<RelationDatabaseListCubit,
                        RelationDatabaseListState>(
                      builder: (context, state) {
                        final databaseMeta =
                            state.databaseMetas.firstWhereOrNull(
                          (meta) => meta.databaseId == typeOption.databaseId,
                        );
                        return FlowyText(
                          databaseMeta == null
                              ? LocaleKeys
                                  .grid_relation_relatedDatabasePlaceholder
                                  .tr()
                              : databaseMeta.databaseName,
                          color: databaseMeta == null
                              ? Theme.of(context).hintColor
                              : null,
                          overflow: TextOverflow.ellipsis,
                        );
                      },
                    ),
                    rightIcon: const FlowySvg(FlowySvgs.more_s),
                  ),
                ),
                popupBuilder: (popoverContext) {
                  return BlocProvider.value(
                    value: context.read<RelationDatabaseListCubit>(),
                    child: _DatabaseList(
                      onSelectDatabase: (newDatabaseId) {
                        final newTypeOption = _updateTypeOption(
                          typeOption: typeOption,
                          databaseId: newDatabaseId,
                        );
                        onTypeOptionUpdated(newTypeOption.writeToBuffer());
                        PopoverContainer.of(context).close();
                      },
                      currentDatabaseId: typeOption.databaseId,
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  RelationTypeOptionPB _parseTypeOptionData(List<int> data) {
    return RelationTypeOptionDataParser().fromBuffer(data);
  }

  RelationTypeOptionPB _updateTypeOption({
    required RelationTypeOptionPB typeOption,
    required String databaseId,
  }) {
    typeOption.freeze();
    return typeOption.rebuild((typeOption) {
      typeOption.databaseId = databaseId;
    });
  }
}

class _DatabaseList extends StatelessWidget {
  const _DatabaseList({
    required this.onSelectDatabase,
    required this.currentDatabaseId,
  });

  final String currentDatabaseId;
  final void Function(String databaseId) onSelectDatabase;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RelationDatabaseListCubit, RelationDatabaseListState>(
      builder: (context, state) {
        final children = state.databaseMetas.map((meta) {
          return SizedBox(
            height: GridSize.popoverItemHeight,
            child: FlowyButton(
              onTap: () => onSelectDatabase(meta.databaseId),
              text: FlowyText.medium(
                meta.databaseName,
                overflow: TextOverflow.ellipsis,
              ),
              rightIcon: meta.databaseId == currentDatabaseId
                  ? const FlowySvg(
                      FlowySvgs.check_s,
                    )
                  : null,
            ),
          );
        }).toList();

        return ListView.separated(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          separatorBuilder: (_, __) =>
              VSpace(GridSize.typeOptionSeparatorHeight),
          itemCount: children.length,
          itemBuilder: (context, index) => children[index],
        );
      },
    );
  }
}
