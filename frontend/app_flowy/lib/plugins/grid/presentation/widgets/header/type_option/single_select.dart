import 'package:app_flowy/plugins/grid/application/field/type_option/single_select_type_option.dart';
import 'package:app_flowy/plugins/grid/application/field/type_option/type_option_context.dart';
import 'package:flutter/material.dart';
import '../field_type_option_editor.dart';
import 'package:appflowy_popover/popover.dart';
import 'builder.dart';
import 'select_option.dart';

class SingleSelectTypeOptionWidgetBuilder extends TypeOptionWidgetBuilder {
  final SingleSelectTypeOptionWidget _widget;

  SingleSelectTypeOptionWidgetBuilder(
    SingleSelectTypeOptionContext singleSelectTypeOption,
    PopoverMutex popoverMutex,
  ) : _widget = SingleSelectTypeOptionWidget(
          selectOptionAction: SingleSelectAction(
            fieldId: singleSelectTypeOption.fieldId,
            gridId: singleSelectTypeOption.gridId,
            typeOptionContext: singleSelectTypeOption,
          ),
          popoverMutex: popoverMutex,
        );

  @override
  Widget? build(BuildContext context) => _widget;
}

class SingleSelectTypeOptionWidget extends TypeOptionWidget {
  final SingleSelectAction selectOptionAction;
  final PopoverMutex? popoverMutex;

  const SingleSelectTypeOptionWidget({
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
