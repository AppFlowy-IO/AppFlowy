///
//  Generated code. Do not modify.
//  source: sort_entities.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

// ignore_for_file: UNDEFINED_SHOWN_NAME
import 'dart:core' as $core;
import 'package:protobuf/protobuf.dart' as $pb;

class GridSortConditionPB extends $pb.ProtobufEnum {
  static const GridSortConditionPB Ascending = GridSortConditionPB._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'Ascending');
  static const GridSortConditionPB Descending = GridSortConditionPB._(1, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'Descending');

  static const $core.List<GridSortConditionPB> values = <GridSortConditionPB> [
    Ascending,
    Descending,
  ];

  static final $core.Map<$core.int, GridSortConditionPB> _byValue = $pb.ProtobufEnum.initByValue(values);
  static GridSortConditionPB? valueOf($core.int value) => _byValue[value];

  const GridSortConditionPB._($core.int v, $core.String n) : super(v, n);
}

