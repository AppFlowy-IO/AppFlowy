import 'package:app_flowy/workspace/application/grid/field/type_option/type_option_service.dart';
import 'package:app_flowy/workspace/presentation/plugins/grid/src/widgets/header/field_editor_pannel.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/checkbox_type_option.pb.dart';
import 'package:flutter/material.dart';

typedef CheckboxTypeOptionContext = TypeOptionContext<CheckboxTypeOption>;

class CheckboxTypeOptionDataBuilder extends TypeOptionDataBuilder<CheckboxTypeOption> {
  @override
  CheckboxTypeOption fromBuffer(List<int> buffer) {
    return CheckboxTypeOption.fromBuffer(buffer);
  }
}

class CheckboxTypeOptionBuilder extends TypeOptionBuilder {
  CheckboxTypeOptionBuilder(CheckboxTypeOptionContext typeOptionContext);

  @override
  Widget? get customWidget => null;
}
