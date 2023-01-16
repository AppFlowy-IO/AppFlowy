///
//  Generated code. Do not modify.
//  source: date_filter.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'date_filter.pbenum.dart';

export 'date_filter.pbenum.dart';

enum DateFilterPB_OneOfStart {
  start, 
  notSet
}

enum DateFilterPB_OneOfEnd {
  end, 
  notSet
}

enum DateFilterPB_OneOfTimestamp {
  timestamp, 
  notSet
}

class DateFilterPB extends $pb.GeneratedMessage {
  static const $core.Map<$core.int, DateFilterPB_OneOfStart> _DateFilterPB_OneOfStartByTag = {
    2 : DateFilterPB_OneOfStart.start,
    0 : DateFilterPB_OneOfStart.notSet
  };
  static const $core.Map<$core.int, DateFilterPB_OneOfEnd> _DateFilterPB_OneOfEndByTag = {
    3 : DateFilterPB_OneOfEnd.end,
    0 : DateFilterPB_OneOfEnd.notSet
  };
  static const $core.Map<$core.int, DateFilterPB_OneOfTimestamp> _DateFilterPB_OneOfTimestampByTag = {
    4 : DateFilterPB_OneOfTimestamp.timestamp,
    0 : DateFilterPB_OneOfTimestamp.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'DateFilterPB', createEmptyInstance: create)
    ..oo(0, [2])
    ..oo(1, [3])
    ..oo(2, [4])
    ..e<DateFilterConditionPB>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'condition', $pb.PbFieldType.OE, defaultOrMaker: DateFilterConditionPB.DateIs, valueOf: DateFilterConditionPB.valueOf, enumValues: DateFilterConditionPB.values)
    ..aInt64(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'start')
    ..aInt64(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'end')
    ..aInt64(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'timestamp')
    ..hasRequiredFields = false
  ;

  DateFilterPB._() : super();
  factory DateFilterPB({
    DateFilterConditionPB? condition,
    $fixnum.Int64? start,
    $fixnum.Int64? end,
    $fixnum.Int64? timestamp,
  }) {
    final _result = create();
    if (condition != null) {
      _result.condition = condition;
    }
    if (start != null) {
      _result.start = start;
    }
    if (end != null) {
      _result.end = end;
    }
    if (timestamp != null) {
      _result.timestamp = timestamp;
    }
    return _result;
  }
  factory DateFilterPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory DateFilterPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  DateFilterPB clone() => DateFilterPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  DateFilterPB copyWith(void Function(DateFilterPB) updates) => super.copyWith((message) => updates(message as DateFilterPB)) as DateFilterPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static DateFilterPB create() => DateFilterPB._();
  DateFilterPB createEmptyInstance() => create();
  static $pb.PbList<DateFilterPB> createRepeated() => $pb.PbList<DateFilterPB>();
  @$core.pragma('dart2js:noInline')
  static DateFilterPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<DateFilterPB>(create);
  static DateFilterPB? _defaultInstance;

  DateFilterPB_OneOfStart whichOneOfStart() => _DateFilterPB_OneOfStartByTag[$_whichOneof(0)]!;
  void clearOneOfStart() => clearField($_whichOneof(0));

  DateFilterPB_OneOfEnd whichOneOfEnd() => _DateFilterPB_OneOfEndByTag[$_whichOneof(1)]!;
  void clearOneOfEnd() => clearField($_whichOneof(1));

  DateFilterPB_OneOfTimestamp whichOneOfTimestamp() => _DateFilterPB_OneOfTimestampByTag[$_whichOneof(2)]!;
  void clearOneOfTimestamp() => clearField($_whichOneof(2));

  @$pb.TagNumber(1)
  DateFilterConditionPB get condition => $_getN(0);
  @$pb.TagNumber(1)
  set condition(DateFilterConditionPB v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasCondition() => $_has(0);
  @$pb.TagNumber(1)
  void clearCondition() => clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get start => $_getI64(1);
  @$pb.TagNumber(2)
  set start($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasStart() => $_has(1);
  @$pb.TagNumber(2)
  void clearStart() => clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get end => $_getI64(2);
  @$pb.TagNumber(3)
  set end($fixnum.Int64 v) { $_setInt64(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasEnd() => $_has(2);
  @$pb.TagNumber(3)
  void clearEnd() => clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get timestamp => $_getI64(3);
  @$pb.TagNumber(4)
  set timestamp($fixnum.Int64 v) { $_setInt64(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasTimestamp() => $_has(3);
  @$pb.TagNumber(4)
  void clearTimestamp() => clearField(4);
}

