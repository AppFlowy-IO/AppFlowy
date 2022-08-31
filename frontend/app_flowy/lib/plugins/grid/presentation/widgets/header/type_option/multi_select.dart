import 'package:app_flowy/plugins/grid/application/field/type_option/multi_select_type_option.dart';
import 'package:app_flowy/plugins/grid/application/field/type_option/type_option_context.dart';
import 'package:flutter/material.dart';
import 'package:appflowy_popover/popover.dart';

import '../field_type_option_editor.dart';
import 'builder.dart';
import 'select_option.dart';

class MultiSelectTypeOptionWidgetBuilder extends TypeOptionWidgetBuilder {
  final MultiSelectTypeOptionWidget _widget;

  MultiSelectTypeOptionWidgetBuilder(
    MultiSelectTypeOptionContext typeOptionContext,
    TypeOptionOverlayDelegate overlayDelegate,
  ) : _widget = MultiSelectTypeOptionWidget(
          selectOptionAction: MultiSelectAction(
            fieldId: typeOptionContext.fieldId,
            gridId: typeOptionContext.gridId,
            typeOptionContext: typeOptionContext,
          ),
          overlayDelegate: overlayDelegate,
        );

  @override
  Widget? build(BuildContext context) => _widget;
}

class MultiSelectTypeOptionWidget extends TypeOptionWidget {
  final MultiSelectAction selectOptionAction;
  final TypeOptionOverlayDelegate overlayDelegate;

  const MultiSelectTypeOptionWidget({
    required this.selectOptionAction,
    required this.overlayDelegate,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SelectOptionTypeOptionWidget(
      options: selectOptionAction.typeOption.options,
      beginEdit: () {
        overlayDelegate.hideOverlay(context);
        PopoverContainerState.of(context).closeAll();
      },
      overlayDelegate: overlayDelegate,
      typeOptionAction: selectOptionAction,
      // key: ValueKey(state.typeOption.hashCode),
    );
  }
}
