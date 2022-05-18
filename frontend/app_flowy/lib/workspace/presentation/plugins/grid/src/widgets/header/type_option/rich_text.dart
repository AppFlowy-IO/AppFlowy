import 'package:app_flowy/workspace/application/grid/field/type_option/type_option_service.dart';
import 'package:app_flowy/workspace/presentation/plugins/grid/src/widgets/header/field_editor_pannel.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/text_type_option.pb.dart';

import 'package:flutter/material.dart';

typedef RichTextTypeOptionContext = TypeOptionContext<RichTextTypeOption>;

class RichTextTypeOptionDataBuilder extends TypeOptionDataBuilder<RichTextTypeOption> {
  @override
  RichTextTypeOption fromBuffer(List<int> buffer) {
    return RichTextTypeOption.fromBuffer(buffer);
  }
}

class RichTextTypeOptionBuilder extends TypeOptionBuilder {
  RichTextTypeOptionBuilder(RichTextTypeOptionContext typeOptionContext);

  @override
  Widget? get customWidget => null;
}
