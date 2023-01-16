///
//  Generated code. Do not modify.
//  source: date_type_option_entities.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'cell_entities.pb.dart' as $0;

export 'date_type_option_entities.pbenum.dart';

class DateCellDataPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'DateCellDataPB', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'date')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'time')
    ..aInt64(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'timestamp')
    ..hasRequiredFields = false
  ;

  DateCellDataPB._() : super();
  factory DateCellDataPB({
    $core.String? date,
    $core.String? time,
    $fixnum.Int64? timestamp,
  }) {
    final _result = create();
    if (date != null) {
      _result.date = date;
    }
    if (time != null) {
      _result.time = time;
    }
    if (timestamp != null) {
      _result.timestamp = timestamp;
    }
    return _result;
  }
  factory DateCellDataPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory DateCellDataPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  DateCellDataPB clone() => DateCellDataPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  DateCellDataPB copyWith(void Function(DateCellDataPB) updates) => super.copyWith((message) => updates(message as DateCellDataPB)) as DateCellDataPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static DateCellDataPB create() => DateCellDataPB._();
  DateCellDataPB createEmptyInstance() => create();
  static $pb.PbList<DateCellDataPB> createRepeated() => $pb.PbList<DateCellDataPB>();
  @$core.pragma('dart2js:noInline')
  static DateCellDataPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<DateCellDataPB>(create);
  static DateCellDataPB? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get date => $_getSZ(0);
  @$pb.TagNumber(1)
  set date($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasDate() => $_has(0);
  @$pb.TagNumber(1)
  void clearDate() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get time => $_getSZ(1);
  @$pb.TagNumber(2)
  set time($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasTime() => $_has(1);
  @$pb.TagNumber(2)
  void clearTime() => clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get timestamp => $_getI64(2);
  @$pb.TagNumber(3)
  set timestamp($fixnum.Int64 v) { $_setInt64(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasTimestamp() => $_has(2);
  @$pb.TagNumber(3)
  void clearTimestamp() => clearField(3);
}

enum DateChangesetPB_OneOfDate {
  date, 
  notSet
}

enum DateChangesetPB_OneOfTime {
  time, 
  notSet
}

class DateChangesetPB extends $pb.GeneratedMessage {
  static const $core.Map<$core.int, DateChangesetPB_OneOfDate> _DateChangesetPB_OneOfDateByTag = {
    2 : DateChangesetPB_OneOfDate.date,
    0 : DateChangesetPB_OneOfDate.notSet
  };
  static const $core.Map<$core.int, DateChangesetPB_OneOfTime> _DateChangesetPB_OneOfTimeByTag = {
    3 : DateChangesetPB_OneOfTime.time,
    0 : DateChangesetPB_OneOfTime.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'DateChangesetPB', createEmptyInstance: create)
    ..oo(0, [2])
    ..oo(1, [3])
    ..aOM<$0.CellPathPB>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'cellPath', subBuilder: $0.CellPathPB.create)
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'date')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'time')
    ..aOB(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'isUtc')
    ..hasRequiredFields = false
  ;

  DateChangesetPB._() : super();
  factory DateChangesetPB({
    $0.CellPathPB? cellPath,
    $core.String? date,
    $core.String? time,
    $core.bool? isUtc,
  }) {
    final _result = create();
    if (cellPath != null) {
      _result.cellPath = cellPath;
    }
    if (date != null) {
      _result.date = date;
    }
    if (time != null) {
      _result.time = time;
    }
    if (isUtc != null) {
      _result.isUtc = isUtc;
    }
    return _result;
  }
  factory DateChangesetPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory DateChangesetPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  DateChangesetPB clone() => DateChangesetPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  DateChangesetPB copyWith(void Function(DateChangesetPB) updates) => super.copyWith((message) => updates(message as DateChangesetPB)) as DateChangesetPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static DateChangesetPB create() => DateChangesetPB._();
  DateChangesetPB createEmptyInstance() => create();
  static $pb.PbList<DateChangesetPB> createRepeated() => $pb.PbList<DateChangesetPB>();
  @$core.pragma('dart2js:noInline')
  static DateChangesetPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<DateChangesetPB>(create);
  static DateChangesetPB? _defaultInstance;

  DateChangesetPB_OneOfDate whichOneOfDate() => _DateChangesetPB_OneOfDateByTag[$_whichOneof(0)]!;
  void clearOneOfDate() => clearField($_whichOneof(0));

  DateChangesetPB_OneOfTime whichOneOfTime() => _DateChangesetPB_OneOfTimeByTag[$_whichOneof(1)]!;
  void clearOneOfTime() => clearField($_whichOneof(1));

  @$pb.TagNumber(1)
  $0.CellPathPB get cellPath => $_getN(0);
  @$pb.TagNumber(1)
  set cellPath($0.CellPathPB v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasCellPath() => $_has(0);
  @$pb.TagNumber(1)
  void clearCellPath() => clearField(1);
  @$pb.TagNumber(1)
  $0.CellPathPB ensureCellPath() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.String get date => $_getSZ(1);
  @$pb.TagNumber(2)
  set date($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasDate() => $_has(1);
  @$pb.TagNumber(2)
  void clearDate() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get time => $_getSZ(2);
  @$pb.TagNumber(3)
  set time($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasTime() => $_has(2);
  @$pb.TagNumber(3)
  void clearTime() => clearField(3);

  @$pb.TagNumber(4)
  $core.bool get isUtc => $_getBF(3);
  @$pb.TagNumber(4)
  set isUtc($core.bool v) { $_setBool(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasIsUtc() => $_has(3);
  @$pb.TagNumber(4)
  void clearIsUtc() => clearField(4);
}

