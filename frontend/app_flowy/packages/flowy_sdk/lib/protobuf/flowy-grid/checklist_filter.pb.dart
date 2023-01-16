///
//  Generated code. Do not modify.
//  source: checklist_filter.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'checklist_filter.pbenum.dart';

export 'checklist_filter.pbenum.dart';

class ChecklistFilterPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'ChecklistFilterPB', createEmptyInstance: create)
    ..e<ChecklistFilterConditionPB>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'condition', $pb.PbFieldType.OE, defaultOrMaker: ChecklistFilterConditionPB.IsComplete, valueOf: ChecklistFilterConditionPB.valueOf, enumValues: ChecklistFilterConditionPB.values)
    ..hasRequiredFields = false
  ;

  ChecklistFilterPB._() : super();
  factory ChecklistFilterPB({
    ChecklistFilterConditionPB? condition,
  }) {
    final _result = create();
    if (condition != null) {
      _result.condition = condition;
    }
    return _result;
  }
  factory ChecklistFilterPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ChecklistFilterPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ChecklistFilterPB clone() => ChecklistFilterPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ChecklistFilterPB copyWith(void Function(ChecklistFilterPB) updates) => super.copyWith((message) => updates(message as ChecklistFilterPB)) as ChecklistFilterPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static ChecklistFilterPB create() => ChecklistFilterPB._();
  ChecklistFilterPB createEmptyInstance() => create();
  static $pb.PbList<ChecklistFilterPB> createRepeated() => $pb.PbList<ChecklistFilterPB>();
  @$core.pragma('dart2js:noInline')
  static ChecklistFilterPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ChecklistFilterPB>(create);
  static ChecklistFilterPB? _defaultInstance;

  @$pb.TagNumber(1)
  ChecklistFilterConditionPB get condition => $_getN(0);
  @$pb.TagNumber(1)
  set condition(ChecklistFilterConditionPB v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasCondition() => $_has(0);
  @$pb.TagNumber(1)
  void clearCondition() => clearField(1);
}

