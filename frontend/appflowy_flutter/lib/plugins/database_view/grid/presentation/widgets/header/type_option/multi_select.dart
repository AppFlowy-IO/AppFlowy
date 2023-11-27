import 'package:appflowy/plugins/database_view/application/field/type_option/multi_select_type_option.dart';
import 'package:appflowy/plugins/database_view/application/field/type_option/type_option_context.dart';
import 'package:flutter/material.dart';
import 'package:appflowy_popover/appflowy_popover.dart';

import '../field_type_option_editor.dart';
import 'builder.dart';
import 'select_option.dart';

class MultiSelectTypeOptionWidgetBuilder extends TypeOptionWidgetBuilder {
  final MultiSelectTypeOptionWidget _widget;

  MultiSelectTypeOptionWidgetBuilder(
    MultiSelectTypeOptionContext typeOptionContext,
    PopoverMutex popoverMutex,
  ) : _widget = MultiSelectTypeOptionWidget(
          selectOptionAction: MultiSelectAction(
            fieldId: typeOptionContext.fieldId,
            viewId: typeOptionContext.viewId,
            typeOptionContext: typeOptionContext,
          ),
          popoverMutex: popoverMutex,
        );

  @override
  Widget? build(BuildContext context) => _widget;
}

class MultiSelectTypeOptionWidget extends TypeOptionWidget {
  final MultiSelectAction selectOptionAction;
  final PopoverMutex? popoverMutex;

  const MultiSelectTypeOptionWidget({
    super.key,
    required this.selectOptionAction,
    this.popoverMutex,
  });

  @override
  Widget build(BuildContext context) {
    return SelectOptionTypeOptionWidget(
      options: selectOptionAction.typeOption.options,
      beginEdit: () {
        PopoverContainer.of(context).closeAll();
      },
      popoverMutex: popoverMutex,
      typeOptionAction: selectOptionAction,
      // key: ValueKey(state.typeOption.hashCode),
    );
  }
}
