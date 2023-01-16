///
//  Generated code. Do not modify.
//  source: select_type_option.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

// ignore_for_file: UNDEFINED_SHOWN_NAME
import 'dart:core' as $core;
import 'package:protobuf/protobuf.dart' as $pb;

class SelectOptionColorPB extends $pb.ProtobufEnum {
  static const SelectOptionColorPB Purple = SelectOptionColorPB._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'Purple');
  static const SelectOptionColorPB Pink = SelectOptionColorPB._(1, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'Pink');
  static const SelectOptionColorPB LightPink = SelectOptionColorPB._(2, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'LightPink');
  static const SelectOptionColorPB Orange = SelectOptionColorPB._(3, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'Orange');
  static const SelectOptionColorPB Yellow = SelectOptionColorPB._(4, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'Yellow');
  static const SelectOptionColorPB Lime = SelectOptionColorPB._(5, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'Lime');
  static const SelectOptionColorPB Green = SelectOptionColorPB._(6, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'Green');
  static const SelectOptionColorPB Aqua = SelectOptionColorPB._(7, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'Aqua');
  static const SelectOptionColorPB Blue = SelectOptionColorPB._(8, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'Blue');

  static const $core.List<SelectOptionColorPB> values = <SelectOptionColorPB> [
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

  static final $core.Map<$core.int, SelectOptionColorPB> _byValue = $pb.ProtobufEnum.initByValue(values);
  static SelectOptionColorPB? valueOf($core.int value) => _byValue[value];

  const SelectOptionColorPB._($core.int v, $core.String n) : super(v, n);
}

