///
//  Generated code. Do not modify.
//  source: view_create.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

// ignore_for_file: UNDEFINED_SHOWN_NAME
import 'dart:core' as $core;
import 'package:protobuf/protobuf.dart' as $pb;

class ViewType extends $pb.ProtobufEnum {
  static const ViewType Blank = ViewType._(
      0,
      const $core.bool.fromEnvironment('protobuf.omit_enum_names')
          ? ''
          : 'Blank');
  static const ViewType Doc = ViewType._(
      1,
      const $core.bool.fromEnvironment('protobuf.omit_enum_names')
          ? ''
          : 'Doc');

  static const $core.List<ViewType> values = <ViewType>[
    Blank,
    Doc,
  ];

  static final $core.Map<$core.int, ViewType> _byValue =
      $pb.ProtobufEnum.initByValue(values);
  static ViewType? valueOf($core.int value) => _byValue[value];

  const ViewType._($core.int v, $core.String n) : super(v, n);
}
