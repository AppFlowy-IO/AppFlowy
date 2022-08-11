import 'package:app_flowy/plugins/grid/application/field/type_option/type_option_service.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/text_type_option.pb.dart';
import 'package:flutter/material.dart';
import 'builder.dart';

typedef RichTextTypeOptionContext = TypeOptionWidgetContext<RichTextTypeOption>;

class RichTextTypeOptionWidgetDataParser
    extends TypeOptionDataParser<RichTextTypeOption> {
  @override
  RichTextTypeOption fromBuffer(List<int> buffer) {
    return RichTextTypeOption.fromBuffer(buffer);
  }
}

class RichTextTypeOptionWidgetBuilder extends TypeOptionWidgetBuilder {
  RichTextTypeOptionWidgetBuilder(RichTextTypeOptionContext typeOptionContext);

  @override
  Widget? build(BuildContext context) => null;
}
