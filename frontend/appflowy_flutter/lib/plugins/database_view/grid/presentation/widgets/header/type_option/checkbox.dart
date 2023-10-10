import 'package:appflowy/plugins/database_view/application/field/type_option/type_option_parser.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pb.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flutter/widgets.dart';

class CheckboxTypeOptionEditor extends StatelessWidget {
  final FieldPB field;
  final CheckboxTypeOptionParser parser;
  final PopoverMutex popoverMutex;

  const CheckboxTypeOptionEditor({
    required this.parser,
    required this.popoverMutex,
    required this.field,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
