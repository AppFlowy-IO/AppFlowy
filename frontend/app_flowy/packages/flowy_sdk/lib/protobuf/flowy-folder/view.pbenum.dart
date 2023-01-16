///
//  Generated code. Do not modify.
//  source: view.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

// ignore_for_file: UNDEFINED_SHOWN_NAME
import 'dart:core' as $core;
import 'package:protobuf/protobuf.dart' as $pb;

class ViewDataFormatPB extends $pb.ProtobufEnum {
  static const ViewDataFormatPB DeltaFormat = ViewDataFormatPB._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'DeltaFormat');
  static const ViewDataFormatPB DatabaseFormat = ViewDataFormatPB._(1, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'DatabaseFormat');
  static const ViewDataFormatPB TreeFormat = ViewDataFormatPB._(2, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'TreeFormat');

  static const $core.List<ViewDataFormatPB> values = <ViewDataFormatPB> [
    DeltaFormat,
    DatabaseFormat,
    TreeFormat,
  ];

  static final $core.Map<$core.int, ViewDataFormatPB> _byValue = $pb.ProtobufEnum.initByValue(values);
  static ViewDataFormatPB? valueOf($core.int value) => _byValue[value];

  const ViewDataFormatPB._($core.int v, $core.String n) : super(v, n);
}

class ViewLayoutTypePB extends $pb.ProtobufEnum {
  static const ViewLayoutTypePB Document = ViewLayoutTypePB._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'Document');
  static const ViewLayoutTypePB Grid = ViewLayoutTypePB._(3, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'Grid');
  static const ViewLayoutTypePB Board = ViewLayoutTypePB._(4, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'Board');

  static const $core.List<ViewLayoutTypePB> values = <ViewLayoutTypePB> [
    Document,
    Grid,
    Board,
  ];

  static final $core.Map<$core.int, ViewLayoutTypePB> _byValue = $pb.ProtobufEnum.initByValue(values);
  static ViewLayoutTypePB? valueOf($core.int value) => _byValue[value];

  const ViewLayoutTypePB._($core.int v, $core.String n) : super(v, n);
}

class MoveFolderItemType extends $pb.ProtobufEnum {
  static const MoveFolderItemType MoveApp = MoveFolderItemType._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'MoveApp');
  static const MoveFolderItemType MoveView = MoveFolderItemType._(1, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'MoveView');

  static const $core.List<MoveFolderItemType> values = <MoveFolderItemType> [
    MoveApp,
    MoveView,
  ];

  static final $core.Map<$core.int, MoveFolderItemType> _byValue = $pb.ProtobufEnum.initByValue(values);
  static MoveFolderItemType? valueOf($core.int value) => _byValue[value];

  const MoveFolderItemType._($core.int v, $core.String n) : super(v, n);
}

