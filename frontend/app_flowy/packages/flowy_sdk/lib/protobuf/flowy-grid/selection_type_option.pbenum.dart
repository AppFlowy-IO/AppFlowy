///
//  Generated code. Do not modify.
//  source: selection_type_option.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

// ignore_for_file: UNDEFINED_SHOWN_NAME
import 'dart:core' as $core;
import 'package:protobuf/protobuf.dart' as $pb;

class SelectOptionColor extends $pb.ProtobufEnum {
  static const SelectOptionColor Purple = SelectOptionColor._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'Purple');
  static const SelectOptionColor Pink = SelectOptionColor._(1, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'Pink');
  static const SelectOptionColor LightPink = SelectOptionColor._(2, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'LightPink');
  static const SelectOptionColor Orange = SelectOptionColor._(3, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'Orange');
  static const SelectOptionColor Yellow = SelectOptionColor._(4, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'Yellow');
  static const SelectOptionColor Lime = SelectOptionColor._(5, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'Lime');
  static const SelectOptionColor Green = SelectOptionColor._(6, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'Green');
  static const SelectOptionColor Aqua = SelectOptionColor._(7, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'Aqua');
  static const SelectOptionColor Blue = SelectOptionColor._(8, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'Blue');

  static const $core.List<SelectOptionColor> values = <SelectOptionColor> [
    Purple,
    Pink,
    LightPink,
    Orange,
    Yellow,
    Lime,
    Green,
    Aqua,
    Blue,
  ];

  static final $core.Map<$core.int, SelectOptionColor> _byValue = $pb.ProtobufEnum.initByValue(values);
  static SelectOptionColor? valueOf($core.int value) => _byValue[value];

  const SelectOptionColor._($core.int v, $core.String n) : super(v, n);
}

