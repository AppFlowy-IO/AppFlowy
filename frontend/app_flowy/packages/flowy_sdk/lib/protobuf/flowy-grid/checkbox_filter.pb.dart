///
//  Generated code. Do not modify.
//  source: checkbox_filter.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'checkbox_filter.pbenum.dart';

export 'checkbox_filter.pbenum.dart';

class CheckboxFilterPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'CheckboxFilterPB', createEmptyInstance: create)
    ..e<CheckboxFilterConditionPB>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'condition', $pb.PbFieldType.OE, defaultOrMaker: CheckboxFilterConditionPB.IsChecked, valueOf: CheckboxFilterConditionPB.valueOf, enumValues: CheckboxFilterConditionPB.values)
    ..hasRequiredFields = false
  ;

  CheckboxFilterPB._() : super();
  factory CheckboxFilterPB({
    CheckboxFilterConditionPB? condition,
  }) {
    final _result = create();
    if (condition != null) {
      _result.condition = condition;
    }
    return _result;
  }
  factory CheckboxFilterPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory CheckboxFilterPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  CheckboxFilterPB clone() => CheckboxFilterPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  CheckboxFilterPB copyWith(void Function(CheckboxFilterPB) updates) => super.copyWith((message) => updates(message as CheckboxFilterPB)) as CheckboxFilterPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static CheckboxFilterPB create() => CheckboxFilterPB._();
  CheckboxFilterPB createEmptyInstance() => create();
  static $pb.PbList<CheckboxFilterPB> createRepeated() => $pb.PbList<CheckboxFilterPB>();
  @$core.pragma('dart2js:noInline')
  static CheckboxFilterPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CheckboxFilterPB>(create);
  static CheckboxFilterPB? _defaultInstance;

  @$pb.TagNumber(1)
  CheckboxFilterConditionPB get condition => $_getN(0);
  @$pb.TagNumber(1)
  set condition(CheckboxFilterConditionPB v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasCondition() => $_has(0);
  @$pb.TagNumber(1)
  void clearCondition() => clearField(1);
}

