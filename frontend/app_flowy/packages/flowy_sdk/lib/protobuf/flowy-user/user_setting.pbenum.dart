///
//  Generated code. Do not modify.
//  source: user_setting.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

// ignore_for_file: UNDEFINED_SHOWN_NAME
import 'dart:core' as $core;
import 'package:protobuf/protobuf.dart' as $pb;

class ThemeModePB extends $pb.ProtobufEnum {
  static const ThemeModePB Light = ThemeModePB._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'Light');
  static const ThemeModePB Dark = ThemeModePB._(1, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'Dark');
  static const ThemeModePB System = ThemeModePB._(2, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'System');

  static const $core.List<ThemeModePB> values = <ThemeModePB> [
    Light,
    Dark,
    System,
  ];

  static final $core.Map<$core.int, ThemeModePB> _byValue = $pb.ProtobufEnum.initByValue(values);
  static ThemeModePB? valueOf($core.int value) => _byValue[value];

  const ThemeModePB._($core.int v, $core.String n) : super(v, n);
}

