import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/workspace/application/grid/prelude.dart';
import 'package:app_flowy/workspace/presentation/plugins/grid/src/layout/sizes.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:app_flowy/generated/locale_keys.g.dart';

class GridFieldCellActionSheet extends StatelessWidget with FlowyOverlayDelegate {
  final GridFieldCellContext cellContext;
  final VoidCallback onEdited;
  const GridFieldCellActionSheet({required this.cellContext, required this.onEdited, Key? key}) : super(key: key);

  void show(BuildContext overlayContext) {
    FlowyOverlay.of(overlayContext).insertWithAnchor(
      widget: OverlayContainer(
        child: this,
        constraints: BoxConstraints.loose(const Size(240, 200)),
      ),
      identifier: GridFieldCellActionSheet.identifier(),
      anchorContext: overlayContext,
      anchorDirection: AnchorDirection.bottomWithLeftAligned,
      delegate: this,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<FieldActionSheetBloc>(param1: cellContext),
      child: SingleChildScrollView(
        child: Column(
          children: [
            _EditFieldButton(
              onEdited: () {
                FlowyOverlay.of(context).remove(identifier());
                onEdited();
              },
            ),
            const VSpace(6),
            _FieldOperationList(cellContext, () => FlowyOverlay.of(context).remove(identifier())),
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

class _EditFieldButton extends StatelessWidget {
  final Function() onEdited;
  const _EditFieldButton({required this.onEdited, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return BlocBuilder<FieldActionSheetBloc, FieldActionSheetState>(
      builder: (context, state) {
        return SizedBox(
          height: GridSize.typeOptionItemHeight,
          child: FlowyButton(
            text: FlowyText.medium(LocaleKeys.grid_field_editProperty.tr(), fontSize: 12),
            hoverColor: theme.hover,
            onTap: onEdited,
          ),
        );
      },
    );
  }
}

class _FieldOperationList extends StatelessWidget {
  final GridFieldCellContext fieldData;
  final VoidCallback onDismissed;
  const _FieldOperationList(this.fieldData, this.onDismissed, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final actions = FieldAction.values
        .map(
          (action) => FieldActionCell(
            fieldId: fieldData.field.id,
            action: action,
            onTap: onDismissed,
          ),
        )
        .toList();

    return GridView(
      // https://api.flutter.dev/flutter/widgets/AnimatedList/shrinkWrap.html
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 4.0,
        mainAxisSpacing: 8,
      ),
      children: actions,
    );
  }
}

class FieldActionCell extends StatelessWidget {
  final String fieldId;
  final VoidCallback onTap;
  final FieldAction action;

  const FieldActionCell({
    required this.fieldId,
    required this.action,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return FlowyButton(
      text: FlowyText.medium(action.title(), fontSize: 12),
      hoverColor: theme.hover,
      onTap: () {
        action.run(context);
        onTap();
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
        context.read<FieldActionSheetBloc>().add(const FieldActionSheetEvent.hideField());
        break;
      case FieldAction.duplicate:
        context.read<FieldActionSheetBloc>().add(const FieldActionSheetEvent.duplicateField());
        break;
      case FieldAction.delete:
        context.read<FieldActionSheetBloc>().add(const FieldActionSheetEvent.deleteField());
        break;
    }
  }
}
