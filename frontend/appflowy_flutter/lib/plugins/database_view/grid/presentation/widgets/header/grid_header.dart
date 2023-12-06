import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/database/field/bottom_sheet_create_field.dart';
import 'package:appflowy/plugins/database_view/application/field/field_controller.dart';
import 'package:appflowy/plugins/database_view/application/field/field_info.dart';
import 'package:appflowy/plugins/database_view/grid/application/grid_bloc.dart';
import 'package:appflowy/plugins/database_view/grid/application/grid_header_bloc.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/widgets/header/mobile_field_cell.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_editor/appflowy_editor.dart' hide Log;
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:reorderables/reorderables.dart';

import '../../../../application/field/type_option/type_option_service.dart';
import '../../layout/sizes.dart';
import 'field_cell.dart';

class GridHeaderSliverAdaptor extends StatefulWidget {
  final String viewId;
  final ScrollController anchorScrollController;

  const GridHeaderSliverAdaptor({
    required this.viewId,
    required this.anchorScrollController,
    super.key,
  });

  @override
  State<GridHeaderSliverAdaptor> createState() =>
      _GridHeaderSliverAdaptorState();
}

class _GridHeaderSliverAdaptorState extends State<GridHeaderSliverAdaptor> {
  @override
  Widget build(BuildContext context) {
    final fieldController =
        context.read<GridBloc>().databaseController.fieldController;
    return BlocProvider(
      create: (context) {
        return GridHeaderBloc(
          viewId: widget.viewId,
          fieldController: fieldController,
        )..add(const GridHeaderEvent.initial());
      },
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        controller: widget.anchorScrollController,
        child: _GridHeader(
          viewId: widget.viewId,
          fieldController: fieldController,
        ),
      ),
    );
  }
}

class _GridHeader extends StatefulWidget {
  final String viewId;
  final FieldController fieldController;
  const _GridHeader({required this.viewId, required this.fieldController});

  @override
  State<_GridHeader> createState() => _GridHeaderState();
}

class _GridHeaderState extends State<_GridHeader> {
  final Map<String, ValueKey<String>> _gridMap = {};

  /// This is a workaround for [ReorderableRow].
  /// [ReorderableRow] warps the child's key with a [GlobalKey].
  /// It will trigger the child's widget's to recreate.
  /// The state will lose.
  _getKeyById(String id) {
    if (_gridMap.containsKey(id)) {
      return _gridMap[id];
    }
    final newKey = ValueKey(id);
    _gridMap[id] = newKey;
    return newKey;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GridHeaderBloc, GridHeaderState>(
      builder: (context, state) {
        final fields = [...state.fields];
        FieldInfo? firstField;
        if (PlatformExtension.isMobile && fields.isNotEmpty) {
          firstField = fields.removeAt(0);
        }

        final cells = fields
            .map(
              (fieldInfo) => PlatformExtension.isDesktop
                  ? GridFieldCell(
                      key: _getKeyById(fieldInfo.id),
                      viewId: widget.viewId,
                      fieldInfo: fieldInfo,
                      fieldController: widget.fieldController,
                      onTap: () => context
                          .read<GridHeaderBloc>()
                          .add(GridHeaderEvent.startEditingField(fieldInfo.id)),
                      onFieldInsertedOnEitherSide: (fieldId) => context
                          .read<GridHeaderBloc>()
                          .add(GridHeaderEvent.startEditingNewField(fieldId)),
                      onEditorOpened: () => context
                          .read<GridHeaderBloc>()
                          .add(const GridHeaderEvent.endEditingField()),
                      isEditing: state.editingFieldId == fieldInfo.id,
                      isNew: state.newFieldId == fieldInfo.id,
                    )
                  : MobileFieldButton(
                      key: _getKeyById(fieldInfo.id),
                      viewId: widget.viewId,
                      fieldController: widget.fieldController,
                      fieldInfo: fieldInfo,
                    ),
            )
            .toList();

        return RepaintBoundary(
          child: ReorderableRow(
            scrollController: ScrollController(),
            buildDraggableFeedback: (context, constraints, child) => Material(
              color: Colors.transparent,
              child: child,
            ),
            draggingWidgetOpacity: 0,
            header: _cellLeading(firstField),
            needsLongPressDraggable: PlatformExtension.isMobile,
            footer: _CellTrailing(viewId: widget.viewId),
            onReorder: (int oldIndex, int newIndex) {
              _onReorder(
                cells,
                oldIndex,
                context,
                newIndex,
              );
            },
            children: cells,
          ),
        );
      },
    );
  }

  void _onReorder(
    List<Widget> cells,
    int oldIndex,
    BuildContext context,
    int newIndex,
  ) {
    if (cells.length > oldIndex) {
      final field = PlatformExtension.isDesktop
          ? (cells[oldIndex] as GridFieldCell).fieldInfo.field
          : (cells[oldIndex] as MobileFieldButton).fieldInfo.field;
      context
          .read<GridHeaderBloc>()
          .add(GridHeaderEvent.moveField(field, oldIndex, newIndex));
    }
  }

  Widget _cellLeading(FieldInfo? fieldInfo) {
    if (PlatformExtension.isDesktop) {
      return SizedBox(width: GridSize.leadingHeaderPadding);
    } else {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(width: GridSize.leadingHeaderPadding),
          if (fieldInfo != null)
            MobileFieldButton(
              key: _getKeyById(fieldInfo.id),
              viewId: widget.viewId,
              fieldController: widget.fieldController,
              fieldInfo: fieldInfo,
            ),
        ],
      );
    }
  }
}

class _CellTrailing extends StatelessWidget {
  const _CellTrailing({required this.viewId});

  final String viewId;

  @override
  Widget build(BuildContext context) {
    final borderSide =
        BorderSide(color: Theme.of(context).dividerColor, width: 1.0);
    return Container(
      width: GridSize.trailHeaderPadding,
      decoration: PlatformExtension.isDesktop
          ? BoxDecoration(
              border: Border(bottom: borderSide),
            )
          : null,
      padding: GridSize.headerContentInsets,
      child: CreateFieldButton(
        viewId: viewId,
        onFieldCreated: (fieldId) => context
            .read<GridHeaderBloc>()
            .add(GridHeaderEvent.startEditingNewField(fieldId)),
      ),
    );
  }
}

class CreateFieldButton extends StatefulWidget {
  const CreateFieldButton({
    super.key,
    required this.viewId,
    required this.onFieldCreated,
  });

  final String viewId;
  final void Function(String fieldId) onFieldCreated;

  @override
  State<CreateFieldButton> createState() => _CreateFieldButtonState();
}

class _CreateFieldButtonState extends State<CreateFieldButton> {
  @override
  Widget build(BuildContext context) {
    return FlowyButton(
      margin: PlatformExtension.isDesktop
          ? GridSize.cellContentInsets
          : const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      radius: BorderRadius.zero,
      text: FlowyText(
        LocaleKeys.grid_field_newProperty.tr(),
        fontSize: PlatformExtension.isDesktop ? null : 15,
        overflow: TextOverflow.ellipsis,
        color: PlatformExtension.isDesktop ? null : Theme.of(context).hintColor,
      ),
      hoverColor: AFThemeExtension.of(context).greyHover,
      onTap: () async {
        if (PlatformExtension.isMobile) {
          showCreateFieldBottomSheet(context, widget.viewId);
        } else {
          final result = await TypeOptionBackendService.createFieldTypeOption(
            viewId: widget.viewId,
          );
          result.fold(
            (typeOptionPB) => widget.onFieldCreated(typeOptionPB.field_2.id),
            (err) => Log.error("Failed to create field type option: $err"),
          );
        }
      },
      leftIcon: FlowySvg(
        FlowySvgs.add_s,
        size: const Size.square(18),
        color: PlatformExtension.isDesktop ? null : Theme.of(context).hintColor,
      ),
    );
  }
}
