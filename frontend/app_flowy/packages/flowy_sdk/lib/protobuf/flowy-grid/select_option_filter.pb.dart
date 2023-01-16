///
//  Generated code. Do not modify.
//  source: select_option_filter.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'select_option_filter.pbenum.dart';

export 'select_option_filter.pbenum.dart';

class SelectOptionFilterPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'SelectOptionFilterPB', createEmptyInstance: create)
    ..e<SelectOptionConditionPB>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'condition', $pb.PbFieldType.OE, defaultOrMaker: SelectOptionConditionPB.OptionIs, valueOf: SelectOptionConditionPB.valueOf, enumValues: SelectOptionConditionPB.values)
    ..pPS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'optionIds')
    ..hasRequiredFields = false
  ;

  SelectOptionFilterPB._() : super();
  factory SelectOptionFilterPB({
    SelectOptionConditionPB? condition,
    $core.Iterable<$core.String>? optionIds,
  }) {
    final _result = create();
    if (condition != null) {
      _result.condition = condition;
    }
    if (optionIds != null) {
      _result.optionIds.addAll(optionIds);
    }
    return _result;
  }
  factory SelectOptionFilterPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory SelectOptionFilterPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  SelectOptionFilterPB clone() => SelectOptionFilterPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  SelectOptionFilterPB copyWith(void Function(SelectOptionFilterPB) updates) => super.copyWith((message) => updates(message as SelectOptionFilterPB)) as SelectOptionFilterPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static SelectOptionFilterPB create() => SelectOptionFilterPB._();
  SelectOptionFilterPB createEmptyInstance() => create();
  static $pb.PbList<SelectOptionFilterPB> createRepeated() => $pb.PbList<SelectOptionFilterPB>();
  @$core.pragma('dart2js:noInline')
  static SelectOptionFilterPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SelectOptionFilterPB>(create);
  static SelectOptionFilterPB? _defaultInstance;

  @$pb.TagNumber(1)
  SelectOptionConditionPB get condition => $_getN(0);
  @$pb.TagNumber(1)
  set condition(SelectOptionConditionPB v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasCondition() => $_has(0);
  @$pb.TagNumber(1)
  void clearCondition() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.String> get optionIds => $_getList(1);
}

