///
//  Generated code. Do not modify.
//  source: observable.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

// ignore_for_file: UNDEFINED_SHOWN_NAME
import 'dart:core' as $core;
import 'package:protobuf/protobuf.dart' as $pb;

class DocObservable extends $pb.ProtobufEnum {
  static const DocObservable UserCreateDoc = DocObservable._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'UserCreateDoc');

  static const $core.List<DocObservable> values = <DocObservable> [
    UserCreateDoc,
  ];

  static final $core.Map<$core.int, DocObservable> _byValue = $pb.ProtobufEnum.initByValue(values);
  static DocObservable? valueOf($core.int value) => _byValue[value];

  const DocObservable._($core.int v, $core.String n) : super(v, n);
}

