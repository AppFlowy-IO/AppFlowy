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
    PopoverMutex popoverMutex,
  ) : _widget = MultiSelectTypeOptionWidget(
          selectOptionAction: MultiSelectAction(
            fieldId: typeOptionContext.fieldId,
            gridId: typeOptionContext.gridId,
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
    Key? key,
    required this.selectOptionAction,
    this.popoverMutex,
  }) : super(key: key);

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
