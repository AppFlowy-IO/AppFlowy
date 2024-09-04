import 'dart:io';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/application/cell/cell_controller.dart';
import 'package:appflowy/plugins/database/application/field/field_controller.dart';
import 'package:appflowy/plugins/database/application/field/field_info.dart';
import 'package:appflowy/plugins/database/domain/field_service.dart';
import 'package:appflowy/plugins/database/grid/application/row/row_detail_bloc.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/header/desktop_field_cell.dart';
import 'package:appflowy/plugins/database/widgets/field/field_editor.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/actions/block_action_button.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_editor/appflowy_editor.dart' hide Log;
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cell/editable_cell_builder.dart';
import 'accessory/cell_accessory.dart';

/// Display the row properties in a list. Only used in [RowDetailPage].
class RowPropertyList extends StatelessWidget {
  const RowPropertyList({
    super.key,
    required this.viewId,
    required this.fieldController,
    required this.cellBuilder,
  });

  final String viewId;
  final FieldController fieldController;
  final EditableCellBuilder cellBuilder;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RowDetailBloc, RowDetailState>(
      buildWhen: (previous, current) =>
          previous.showHiddenFields != current.showHiddenFields ||
          !listEquals(previous.visibleCells, current.visibleCells),
      builder: (context, state) {
        final children = state.visibleCells
            .mapIndexed(
              (index, cell) => _PropertyCell(
                key: ValueKey('row_detail_${cell.fieldId}'),
                cellContext: cell,
                cellBuilder: cellBuilder,
                fieldController: fieldController,
                index: index,
              ),
            )
            .toList();

        return ReorderableListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          onReorder: (from, to) => context
              .read<RowDetailBloc>()
              .add(RowDetailEvent.reorderField(from, to)),
          buildDefaultDragHandles: false,
          proxyDecorator: (child, index, animation) => Material(
            color: Colors.transparent,
            child: Stack(
              children: [
                BlocProvider.value(
                  value: context.read<RowDetailBloc>(),
                  child: child,
                ),
                MouseRegion(
                  cursor: Platform.isWindows
                      ? SystemMouseCursors.click
                      : SystemMouseCursors.grabbing,
                  child: const SizedBox(
                    width: 16,
                    height: 30,
                    child: FlowySvg(FlowySvgs.drag_element_s),
                  ),
                ),
              ],
            ),
          ),
          footer: Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Column(
              children: [
                if (context.watch<RowDetailBloc>().state.numHiddenFields != 0)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 4.0),
                    child: ToggleHiddenFieldsVisibilityButton(),
                  ),
                CreateRowFieldButton(
                  viewId: viewId,
                  fieldController: fieldController,
                ),
              ],
            ),
          ),
          children: children,
        );
      },
    );
  }
}

class _PropertyCell extends StatefulWidget {
  const _PropertyCell({
    super.key,
    required this.cellContext,
    required this.cellBuilder,
    required this.fieldController,
    required this.index,
  });

  final CellContext cellContext;
  final EditableCellBuilder cellBuilder;
  final FieldController fieldController;
  final int index;

  @override
  State<StatefulWidget> createState() => _PropertyCellState();
}

class _PropertyCellState extends State<_PropertyCell> {
  final PopoverController _popoverController = PopoverController();

  final ValueNotifier<bool> _isFieldHover = ValueNotifier(false);

  @override
  Widget build(BuildContext context) {
    final dragHandle = MouseRegion(
      cursor: Platform.isWindows
          ? SystemMouseCursors.click
          : SystemMouseCursors.grab,
      child: SizedBox(
        width: 16,
        height: 30,
        child: BlocListener<RowDetailBloc, RowDetailState>(
          listenWhen: (previous, current) =>
              previous.editingFieldId != current.editingFieldId,
          listener: (context, state) {
            if (state.editingFieldId == widget.cellContext.fieldId) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _popoverController.show();
              });
            }
          },
          child: ValueListenableBuilder(
            valueListenable: _isFieldHover,
            builder: (_, isHovering, child) =>
                isHovering ? child! : const SizedBox.shrink(),
            child: BlockActionButton(
              onTap: () => context.read<RowDetailBloc>().add(
                    RowDetailEvent.startEditingField(
                      widget.cellContext.fieldId,
                    ),
                  ),
              svg: FlowySvgs.drag_element_s,
              richMessage: TextSpan(
                text: LocaleKeys.grid_rowPage_fieldDragElementTooltip.tr(),
                style: context.tooltipTextStyle(),
              ),
            ),
          ),
        ),
      ),
    );

    final cell = widget.cellBuilder.buildStyled(
      widget.cellContext,
      EditableCellStyle.desktopRowDetail,
    );
    final gesture = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => cell.requestFocus.notify(),
      child: AccessoryHover(
        fieldType: widget.fieldController
            .getField(widget.cellContext.fieldId)!
            .fieldType,
        child: cell,
      ),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      constraints: const BoxConstraints(minHeight: 30),
      child: MouseRegion(
        onEnter: (event) {
          _isFieldHover.value = true;
          cell.cellContainerNotifier.isHover = true;
        },
        onExit: (event) {
          _isFieldHover.value = false;
          cell.cellContainerNotifier.isHover = false;
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ValueListenableBuilder(
              valueListenable: _isFieldHover,
              builder: (context, value, _) {
                return ReorderableDragStartListener(
                  index: widget.index,
                  enabled: value,
                  child: dragHandle,
                );
              },
            ),
            const HSpace(4),
            BlocSelector<RowDetailBloc, RowDetailState, FieldInfo?>(
              selector: (state) => state.fields.firstWhereOrNull(
                (fieldInfo) => fieldInfo.field.id == widget.cellContext.fieldId,
              ),
              builder: (context, fieldInfo) {
                if (fieldInfo == null) {
                  return const SizedBox.shrink();
                }
                return AppFlowyPopover(
                  controller: _popoverController,
                  constraints: BoxConstraints.loose(const Size(240, 600)),
                  margin: EdgeInsets.zero,
                  triggerActions: PopoverTriggerFlags.none,
                  direction: PopoverDirection.bottomWithLeftAligned,
                  onClose: () => context
                      .read<RowDetailBloc>()
                      .add(const RowDetailEvent.endEditingField()),
                  popupBuilder: (popoverContext) => FieldEditor(
                    viewId: widget.fieldController.viewId,
                    fieldInfo: fieldInfo,
                    fieldController: widget.fieldController,
                    isNewField: false,
                  ),
                  child: SizedBox(
                    width: 160,
                    height: 30,
                    child: Tooltip(
                      waitDuration: const Duration(seconds: 1),
                      preferBelow: false,
                      verticalOffset: 15,
                      message: fieldInfo.name,
                      child: FieldCellButton(
                        field: fieldInfo.field,
                        onTap: () => context.read<RowDetailBloc>().add(
                              RowDetailEvent.startEditingField(
                                widget.cellContext.fieldId,
                              ),
                            ),
                        radius: BorderRadius.circular(6),
                        margin: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 6,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const HSpace(8),
            Expanded(child: gesture),
          ],
        ),
      ),
    );
  }
}

class ToggleHiddenFieldsVisibilityButton extends StatelessWidget {
  const ToggleHiddenFieldsVisibilityButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RowDetailBloc, RowDetailState>(
      buildWhen: (previous, current) =>
          previous.showHiddenFields != current.showHiddenFields ||
          previous.numHiddenFields != current.numHiddenFields,
      builder: (context, state) {
        final text = state.showHiddenFields
            ? LocaleKeys.grid_rowPage_hideHiddenFields.plural(
                state.numHiddenFields,
                namedArgs: {'count': '${state.numHiddenFields}'},
              )
            : LocaleKeys.grid_rowPage_showHiddenFields.plural(
                state.numHiddenFields,
                namedArgs: {'count': '${state.numHiddenFields}'},
              );
        final quarterTurns = state.showHiddenFields ? 1 : 3;
        return PlatformExtension.isDesktopOrWeb
            ? _desktop(context, text, quarterTurns)
            : _mobile(context, text, quarterTurns);
      },
    );
  }

  Widget _desktop(BuildContext context, String text, int quarterTurns) {
    return SizedBox(
      height: 30,
      child: FlowyButton(
        text: FlowyText.medium(
          text,
          lineHeight: 1.0,
          color: Theme.of(context).hintColor,
        ),
        hoverColor: AFThemeExtension.of(context).lightGreyHover,
        leftIcon: RotatedBox(
          quarterTurns: quarterTurns,
          child: FlowySvg(
            FlowySvgs.arrow_left_s,
            color: Theme.of(context).hintColor,
          ),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        onTap: () => context.read<RowDetailBloc>().add(
              const RowDetailEvent.toggleHiddenFieldVisibility(),
            ),
      ),
    );
  }

  Widget _mobile(BuildContext context, String text, int quarterTurns) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: double.infinity),
      child: TextButton.icon(
        style: Theme.of(context).textButtonTheme.style?.copyWith(
              shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              overlayColor: WidgetStateProperty.all<Color>(
                Theme.of(context).hoverColor,
              ),
              alignment: AlignmentDirectional.centerStart,
              splashFactory: NoSplash.splashFactory,
              padding: const WidgetStatePropertyAll(
                EdgeInsets.symmetric(vertical: 14, horizontal: 6),
              ),
            ),
        label: FlowyText.medium(
          text,
          fontSize: 15,
          color: Theme.of(context).hintColor,
        ),
        onPressed: () => context
            .read<RowDetailBloc>()
            .add(const RowDetailEvent.toggleHiddenFieldVisibility()),
        icon: RotatedBox(
          quarterTurns: quarterTurns,
          child: FlowySvg(
            FlowySvgs.arrow_left_s,
            color: Theme.of(context).hintColor,
          ),
        ),
      ),
    );
  }
}

class CreateRowFieldButton extends StatelessWidget {
  const CreateRowFieldButton({
    super.key,
    required this.viewId,
    required this.fieldController,
  });

  final String viewId;
  final FieldController fieldController;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      child: FlowyButton(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        text: FlowyText.medium(
          lineHeight: 1.0,
          LocaleKeys.grid_field_newProperty.tr(),
          color: Theme.of(context).hintColor,
        ),
        hoverColor: AFThemeExtension.of(context).lightGreyHover,
        onTap: () async {
          final result = await FieldBackendService.createField(
            viewId: viewId,
          );
          await Future.delayed(const Duration(milliseconds: 50));
          result.fold(
            (field) => context
                .read<RowDetailBloc>()
                .add(RowDetailEvent.startEditingField(field.id)),
            (err) => Log.error("Failed to create field type option: $err"),
          );
        },
        leftIcon: FlowySvg(
          FlowySvgs.add_m,
          color: Theme.of(context).hintColor,
        ),
      ),
    );
  }
}
