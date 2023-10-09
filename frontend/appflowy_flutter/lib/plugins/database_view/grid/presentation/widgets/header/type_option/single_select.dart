import 'package:appflowy/plugins/database_view/application/field/type_option/single_select_type_option.dart';
import 'package:appflowy/plugins/database_view/application/field/type_option/type_option_parser.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flutter/widgets.dart';

import 'select_option.dart';

// class SingleSelectTypeOptionWidgetBuilder extends TypeOptionWidgetBuilder {
//   final SingleSelectTypeOptionWidget _widget;

//   SingleSelectTypeOptionWidgetBuilder(
//     SingleSelectTypeOptionContext singleSelectTypeOption,
//     PopoverMutex popoverMutex,
//   ) : _widget = SingleSelectTypeOptionWidget(
//           selectOptionAction: SingleSelectAction(
//             fieldId: singleSelectTypeOption.fieldId,
//             viewId: singleSelectTypeOption.viewId,
//             typeOptionContext: singleSelectTypeOption,
//           ),
//           popoverMutex: popoverMutex,
//         );

//   @override
//   Widget? build(BuildContext context) => _widget;
// }

class SingleSelectTypeOptionEditor extends StatelessWidget {
  final SingleSelectTypeOptionParser parser;
  final SingleSelectAction selectOptionAction;
  final PopoverMutex? popoverMutex;

  SingleSelectTypeOptionEditor({
    required this.parser,
    this.popoverMutex,
    super.key,
  }) : selectOptionAction = SingleSelectAction(
          fieldId: singleSelectTypeOption.fieldId,
          viewId: singleSelectTypeOption.viewId,
          typeOptionContext: singleSelectTypeOption,
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
