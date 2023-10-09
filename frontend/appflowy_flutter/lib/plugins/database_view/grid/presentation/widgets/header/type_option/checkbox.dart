import 'package:appflowy/plugins/database_view/application/field/type_option/type_option_parser.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flutter/widgets.dart';

class CheckboxTypeOptionEditor extends StatelessWidget {
  final PopoverMutex popoverMutex;
  const CheckboxTypeOptionEditor({
    required CheckboxTypeOptionParser parser,
    required this.popoverMutex,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
