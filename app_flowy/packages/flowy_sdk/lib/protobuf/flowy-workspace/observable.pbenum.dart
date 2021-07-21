///
//  Generated code. Do not modify.
//  source: observable.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

// ignore_for_file: UNDEFINED_SHOWN_NAME
import 'dart:core' as $core;
import 'package:protobuf/protobuf.dart' as $pb;

class ObservableType extends $pb.ProtobufEnum {
  static const ObservableType Unknown = ObservableType._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'Unknown');
  static const ObservableType WorkspaceDidUpdate = ObservableType._(10, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'WorkspaceDidUpdate');
  static const ObservableType AppDidUpdate = ObservableType._(11, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'AppDidUpdate');

  static const $core.List<ObservableType> values = <ObservableType> [
    Unknown,
    WorkspaceDidUpdate,
    AppDidUpdate,
  ];

  static final $core.Map<$core.int, ObservableType> _byValue = $pb.ProtobufEnum.initByValue(values);
  static ObservableType? valueOf($core.int value) => _byValue[value];

  const ObservableType._($core.int v, $core.String n) : super(v, n);
}

