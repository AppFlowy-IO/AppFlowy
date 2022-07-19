import 'package:app_flowy/workspace/application/grid/field/type_option/type_option_service.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/checkbox_type_option.pb.dart';
import 'package:flutter/material.dart';
import 'builder.dart';

typedef CheckboxTypeOptionContext = TypeOptionWidgetContext<CheckboxTypeOption>;

class CheckboxTypeOptionWidgetDataParser extends TypeOptionDataParser<CheckboxTypeOption> {
  @override
  CheckboxTypeOption fromBuffer(List<int> buffer) {
    return CheckboxTypeOption.fromBuffer(buffer);
  }
}

class CheckboxTypeOptionWidgetBuilder extends TypeOptionWidgetBuilder {
  CheckboxTypeOptionWidgetBuilder(CheckboxTypeOptionContext typeOptionContext);

  @override
  Widget? build(BuildContext context) => null;
}
