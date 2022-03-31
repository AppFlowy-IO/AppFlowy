import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/workspace/application/grid/prelude.dart';
import 'package:app_flowy/workspace/presentation/plugins/grid/src/layout/sizes.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'field_operation_list.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:app_flowy/generated/locale_keys.g.dart';

class GridFieldActionSheet extends StatelessWidget with FlowyOverlayDelegate {
  final GridFieldData fieldData;
  final VoidCallback onEdited;
  const GridFieldActionSheet({required this.fieldData, required this.onEdited, Key? key}) : super(key: key);

  static void show(BuildContext overlayContext, GridFieldData fieldData, final VoidCallback onEdited) {
    final editor = GridFieldActionSheet(fieldData: fieldData, onEdited: onEdited);
    FlowyOverlay.of(overlayContext).insertWithAnchor(
      widget: OverlayContainer(
        child: editor,
        constraints: BoxConstraints.loose(const Size(240, 200)),
      ),
      identifier: editor.identifier(),
      anchorContext: overlayContext,
      anchorDirection: AnchorDirection.bottomWithLeftAligned,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<GridFieldBloc>(param1: fieldData),
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
            _FieldOperationList(fieldData, () => FlowyOverlay.of(context).remove(identifier())),
          ],
        ),
      ),
    );
  }

  String identifier() {
    return toString();
  }

  @override
  bool asBarrier() => true;
}

class _EditFieldButton extends StatelessWidget {
  final Function() onEdited;
  const _EditFieldButton({required this.onEdited, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return BlocBuilder<GridFieldBloc, GridFieldState>(
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
  final GridFieldData fieldData;
  final VoidCallback onDismissed;
  const _FieldOperationList(this.fieldData, this.onDismissed, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final actions = FieldAction.values
        .map(
          (action) => FieldActionItem(
            fieldId: fieldData.field.id,
            action: action,
            onTap: onDismissed,
          ),
        )
        .toList();

    return FieldOperationList(actions: actions);
  }
}
