import 'package:app_flowy/workspace/application/grid/field/type_option/type_option_service.dart';
import 'package:app_flowy/workspace/presentation/plugins/grid/src/widgets/header/field_editor_pannel.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/url_type_option.pb.dart';
import 'package:flutter/material.dart';

typedef URLTypeOptionContext = TypeOptionContext<URLTypeOption>;

class URLTypeOptionDataBuilder extends TypeOptionDataBuilder<URLTypeOption> {
  @override
  URLTypeOption fromBuffer(List<int> buffer) {
    return URLTypeOption.fromBuffer(buffer);
  }
}

class URLTypeOptionBuilder extends TypeOptionBuilder {
  URLTypeOptionBuilder(URLTypeOptionContext typeOptionContext);

  @override
  Widget? get customWidget => null;
}
