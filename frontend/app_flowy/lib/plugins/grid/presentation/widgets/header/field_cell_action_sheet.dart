import 'package:app_flowy/plugins/grid/application/field/type_option/type_option_context.dart';
import 'package:app_flowy/plugins/grid/presentation/widgets/header/field_editor.dart';
import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/plugins/grid/application/prelude.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:appflowy_popover/popover.dart';
import 'package:app_flowy/generated/locale_keys.g.dart';

import '../../layout/sizes.dart';

class GridFieldCellActionSheet extends StatelessWidget
    with FlowyOverlayDelegate {
  final GridFieldCellContext cellContext;
  const GridFieldCellActionSheet({required this.cellContext, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<FieldActionSheetBloc>(param1: cellContext),
      child: SingleChildScrollView(
        child: Column(
          children: [
            _EditFieldButton(
              cellContext: cellContext,
            ),
            const VSpace(6),
            _FieldOperationList(cellContext,
                () => FlowyOverlay.of(context).remove(identifier())),
          ],
        ),
      ),
    );
  }

  static String identifier() {
    return (GridFieldCellActionSheet).toString();
  }

  @override
  bool asBarrier() {
    return true;
  }
}

class _EditFieldButton extends StatefulWidget {
  final GridFieldCellContext cellContext;
  const _EditFieldButton({required this.cellContext, Key? key})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _EditFieldButtonState();
}

class _EditFieldButtonState extends State<_EditFieldButton> {
  final popover = PopoverController();

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return BlocBuilder<FieldActionSheetBloc, FieldActionSheetState>(
      builder: (context, state) {
        return SizedBox(
          height: GridSize.typeOptionItemHeight,
          child: Popover(
            controller: popover,
            targetAnchor: Alignment.topRight,
            followerAnchor: Alignment.topLeft,
            offset: const Offset(20, 0),
            popupBuilder: (context) {
              final field = widget.cellContext.field;
              return OverlayContainer(
                constraints: BoxConstraints.loose(const Size(240, 200)),
                child: FieldEditor(
                  gridId: widget.cellContext.gridId,
                  fieldName: field.name,
                  typeOptionLoader: FieldTypeOptionLoader(
                    gridId: widget.cellContext.gridId,
                    field: field,
                  ),
                ),
              );
            },
            child: FlowyButton(
              text: FlowyText.medium(
                LocaleKeys.grid_field_editProperty.tr(),
                fontSize: 12,
              ),
              hoverColor: theme.hover,
              onTap: () => popover.show(),
            ),
          ),
        );
      },
    );
  }
}

class _FieldOperationList extends StatelessWidget {
  final GridFieldCellContext fieldData;
  final VoidCallback onDismissed;
  const _FieldOperationList(this.fieldData, this.onDismissed, {Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView(
      // https://api.flutter.dev/flutter/widgets/AnimatedList/shrinkWrap.html
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 4.0,
        mainAxisSpacing: 8,
      ),
      children: buildCells(),
    );
  }

  List<Widget> buildCells() {
    return FieldAction.values.map(
      (action) {
        bool enable = true;
        switch (action) {
          case FieldAction.delete:
            enable = !fieldData.field.isPrimary;
            break;
          default:
            break;
        }

        return FieldActionCell(
          fieldId: fieldData.field.id,
          action: action,
          onTap: onDismissed,
          enable: enable,
        );
      },
    ).toList();
  }
}

class FieldActionCell extends StatelessWidget {
  final String fieldId;
  final VoidCallback onTap;
  final FieldAction action;
  final bool enable;

  const FieldActionCell({
    required this.fieldId,
    required this.action,
    required this.onTap,
    required this.enable,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return FlowyButton(
      text: FlowyText.medium(action.title(),
          fontSize: 12, color: enable ? null : theme.shader4),
      hoverColor: theme.hover,
      onTap: () {
        if (enable) {
          action.run(context);
          onTap();
        }
      },
      leftIcon: svgWidget(action.iconName(), color: theme.iconColor),
    );
  }
}

enum FieldAction {
  hide,
  duplicate,
  delete,
}

extension _FieldActionExtension on FieldAction {
  String iconName() {
    switch (this) {
      case FieldAction.hide:
        return 'grid/hide';
      case FieldAction.duplicate:
        return 'grid/duplicate';
      case FieldAction.delete:
        return 'grid/delete';
    }
  }

  String title() {
    switch (this) {
      case FieldAction.hide:
        return LocaleKeys.grid_field_hide.tr();
      case FieldAction.duplicate:
        return LocaleKeys.grid_field_duplicate.tr();
      case FieldAction.delete:
        return LocaleKeys.grid_field_delete.tr();
    }
  }

  void run(BuildContext context) {
    switch (this) {
      case FieldAction.hide:
        context
            .read<FieldActionSheetBloc>()
            .add(const FieldActionSheetEvent.hideField());
        break;
      case FieldAction.duplicate:
        context
            .read<FieldActionSheetBloc>()
            .add(const FieldActionSheetEvent.duplicateField());
        break;
      case FieldAction.delete:
        context
            .read<FieldActionSheetBloc>()
            .add(const FieldActionSheetEvent.deleteField());
        break;
    }
  }
}
