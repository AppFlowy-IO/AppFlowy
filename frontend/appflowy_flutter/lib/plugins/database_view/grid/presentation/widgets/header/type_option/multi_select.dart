import 'package:appflowy/plugins/database_view/application/field/type_option/multi_select_type_option.dart';
import 'package:appflowy/plugins/database_view/application/field/type_option/type_option_parser.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flutter/widgets.dart';

import 'select_option.dart';

class MultiSelectTypeOptionEditor extends StatelessWidget {
  final MultiSelectTypeOptionParser parser;
  final MultiSelectAction selectOptionAction;
  final PopoverMutex? popoverMutex;

  MultiSelectTypeOptionEditor({
    required this.parser,
    this.popoverMutex,
    super.key,
  }) : selectOptionAction = MultiSelectAction(
          fieldId: typeOptionContext.fieldId,
          viewId: typeOptionContext.viewId,
          typeOptionContext: typeOptionContext,
        );

  @override
  Widget build(BuildContext context) {
    return SelectOptionTypeOptionWidget(
      options: selectOptionAction.typeOption.options,
      beginEdit: () {
        PopoverContainer.of(context).closeAll();
      },
      popoverMutex: popoverMutex,
      typeOptionAction: selectOptionAction,
    );
  }
}
