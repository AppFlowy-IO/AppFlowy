import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/application/field/type_option/type_option_data_parser.dart';
import 'package:appflowy/plugins/database/grid/presentation/layout/sizes.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-error/protobuf.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:dartz/dartz.dart' show Either;
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
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
          triggerActions: PopoverTriggerFlags.hover | PopoverTriggerFlags.click,
          offset: const Offset(6, 0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            height: GridSize.popoverItemHeight,
            child: FlowyButton(
              text: FlowyText(
                typeOption.databaseId.isEmpty
                    ? LocaleKeys.grid_relation_relatedDatabasePlaceholder.tr()
                    : typeOption.databaseId,
                color: typeOption.databaseId.isEmpty
                    ? Theme.of(context).hintColor
                    : null,
                overflow: TextOverflow.ellipsis,
              ),
              rightIcon: const FlowySvg(FlowySvgs.more_s),
            ),
          ),
          popupBuilder: (context) {
            return _DatabaseList(
              onSelectDatabase: (newDatabaseId) {
                final newTypeOption = _updateTypeOption(
                  typeOption: typeOption,
                  databaseId: newDatabaseId,
                );
                onTypeOptionUpdated(newTypeOption.writeToBuffer());
                PopoverContainer.of(context).close();
              },
              currentDatabaseId:
                  typeOption.databaseId.isEmpty ? null : typeOption.databaseId,
            );
          },
        ),
      ],
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

class _DatabaseList extends StatefulWidget {
  const _DatabaseList({
    required this.onSelectDatabase,
    required this.currentDatabaseId,
  });

  final String? currentDatabaseId;
  final void Function(String databaseId) onSelectDatabase;

  @override
  State<_DatabaseList> createState() => _DatabaseListState();
}

class _DatabaseListState extends State<_DatabaseList> {
  late Future<Either<RepeatedDatabaseDescriptionPB, FlowyError>> future;

  @override
  void initState() {
    super.initState();
    future = DatabaseEventGetDatabases().send();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: future,
      builder: (context, snapshot) {
        final data = snapshot.data;
        if (!snapshot.hasData ||
            snapshot.connectionState != ConnectionState.done ||
            data!.isRight()) {
          return const SizedBox.shrink();
        }

        final databaseIds = data
            .fold<List<DatabaseDescriptionPB>>((l) => l.items, (r) => [])
            .map((databaseDescription) {
          final databaseId = databaseDescription.databaseId;
          return FlowyButton(
            onTap: () => widget.onSelectDatabase(databaseId),
            text: FlowyText.medium(
              databaseId,
              overflow: TextOverflow.ellipsis,
            ),
            rightIcon: databaseId == widget.currentDatabaseId
                ? FlowySvg(
                    FlowySvgs.check_s,
                    color: Theme.of(context).colorScheme.primary,
                  )
                : null,
          );
        }).toList();

        return ListView.separated(
          shrinkWrap: true,
          separatorBuilder: (_, __) =>
              VSpace(GridSize.typeOptionSeparatorHeight),
          itemCount: databaseIds.length,
          itemBuilder: (context, index) => databaseIds[index],
        );
      },
    );
  }
}
