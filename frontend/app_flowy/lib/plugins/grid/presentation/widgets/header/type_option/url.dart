import 'package:app_flowy/plugins/grid/application/field/type_option/type_option_data_controller.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/url_type_option.pb.dart';
import 'package:flutter/material.dart';
import 'builder.dart';

class URLTypeOptionWidgetDataParser
    extends TypeOptionDataParser<URLTypeOption> {
  @override
  URLTypeOption fromBuffer(List<int> buffer) {
    return URLTypeOption.fromBuffer(buffer);
  }
}

class URLTypeOptionWidgetBuilder extends TypeOptionWidgetBuilder {
  URLTypeOptionWidgetBuilder(URLTypeOptionContext typeOptionContext);

  @override
  Widget? build(BuildContext context) => null;
}
