///
//  Generated code. Do not modify.
//  source: date_type_option.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'cell_entities.pb.dart' as $0;

import 'date_type_option.pbenum.dart';

export 'date_type_option.pbenum.dart';

class DateTypeOption extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'DateTypeOption', createEmptyInstance: create)
    ..e<DateFormat>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'dateFormat', $pb.PbFieldType.OE, defaultOrMaker: DateFormat.Local, valueOf: DateFormat.valueOf, enumValues: DateFormat.values)
    ..e<TimeFormat>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'timeFormat', $pb.PbFieldType.OE, defaultOrMaker: TimeFormat.TwelveHour, valueOf: TimeFormat.valueOf, enumValues: TimeFormat.values)
    ..aOB(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'includeTime')
    ..hasRequiredFields = false
  ;

  DateTypeOption._() : super();
  factory DateTypeOption({
    DateFormat? dateFormat,
    TimeFormat? timeFormat,
    $core.bool? includeTime,
  }) {
    final _result = create();
    if (dateFormat != null) {
      _result.dateFormat = dateFormat;
    }
    if (timeFormat != null) {
      _result.timeFormat = timeFormat;
    }
    if (includeTime != null) {
      _result.includeTime = includeTime;
    }
    return _result;
  }
  factory DateTypeOption.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory DateTypeOption.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  DateTypeOption clone() => DateTypeOption()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  DateTypeOption copyWith(void Function(DateTypeOption) updates) => super.copyWith((message) => updates(message as DateTypeOption)) as DateTypeOption; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static DateTypeOption create() => DateTypeOption._();
  DateTypeOption createEmptyInstance() => create();
  static $pb.PbList<DateTypeOption> createRepeated() => $pb.PbList<DateTypeOption>();
  @$core.pragma('dart2js:noInline')
  static DateTypeOption getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<DateTypeOption>(create);
  static DateTypeOption? _defaultInstance;

  @$pb.TagNumber(1)
  DateFormat get dateFormat => $_getN(0);
  @$pb.TagNumber(1)
  set dateFormat(DateFormat v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasDateFormat() => $_has(0);
  @$pb.TagNumber(1)
  void clearDateFormat() => clearField(1);

  @$pb.TagNumber(2)
  TimeFormat get timeFormat => $_getN(1);
  @$pb.TagNumber(2)
  set timeFormat(TimeFormat v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasTimeFormat() => $_has(1);
  @$pb.TagNumber(2)
  void clearTimeFormat() => clearField(2);

  @$pb.TagNumber(3)
  $core.bool get includeTime => $_getBF(2);
  @$pb.TagNumber(3)
  set includeTime($core.bool v) { $_setBool(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasIncludeTime() => $_has(2);
  @$pb.TagNumber(3)
  void clearIncludeTime() => clearField(3);
}

class DateCellData extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'DateCellData', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'date')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'time')
    ..hasRequiredFields = false
  ;

  DateCellData._() : super();
  factory DateCellData({
    $core.String? date,
    $core.String? time,
  }) {
    final _result = create();
    if (date != null) {
      _result.date = date;
    }
    if (time != null) {
      _result.time = time;
    }
    return _result;
  }
  factory DateCellData.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory DateCellData.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  DateCellData clone() => DateCellData()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  DateCellData copyWith(void Function(DateCellData) updates) => super.copyWith((message) => updates(message as DateCellData)) as DateCellData; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static DateCellData create() => DateCellData._();
  DateCellData createEmptyInstance() => create();
  static $pb.PbList<DateCellData> createRepeated() => $pb.PbList<DateCellData>();
  @$core.pragma('dart2js:noInline')
  static DateCellData getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<DateCellData>(create);
  static DateCellData? _defaultInstance;

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
}

enum DateChangesetPayload_OneOfDate {
  date, 
  notSet
}

enum DateChangesetPayload_OneOfTime {
  time, 
  notSet
}

class DateChangesetPayload extends $pb.GeneratedMessage {
  static const $core.Map<$core.int, DateChangesetPayload_OneOfDate> _DateChangesetPayload_OneOfDateByTag = {
    2 : DateChangesetPayload_OneOfDate.date,
    0 : DateChangesetPayload_OneOfDate.notSet
  };
  static const $core.Map<$core.int, DateChangesetPayload_OneOfTime> _DateChangesetPayload_OneOfTimeByTag = {
    3 : DateChangesetPayload_OneOfTime.time,
    0 : DateChangesetPayload_OneOfTime.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'DateChangesetPayload', createEmptyInstance: create)
    ..oo(0, [2])
    ..oo(1, [3])
    ..aOM<$0.CellIdentifierPayload>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'cellIdentifier', subBuilder: $0.CellIdentifierPayload.create)
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'date')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'time')
    ..hasRequiredFields = false
  ;

  DateChangesetPayload._() : super();
  factory DateChangesetPayload({
    $0.CellIdentifierPayload? cellIdentifier,
    $core.String? date,
    $core.String? time,
  }) {
    final _result = create();
    if (cellIdentifier != null) {
      _result.cellIdentifier = cellIdentifier;
    }
    if (date != null) {
      _result.date = date;
    }
    if (time != null) {
      _result.time = time;
    }
    return _result;
  }
  factory DateChangesetPayload.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory DateChangesetPayload.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  DateChangesetPayload clone() => DateChangesetPayload()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  DateChangesetPayload copyWith(void Function(DateChangesetPayload) updates) => super.copyWith((message) => updates(message as DateChangesetPayload)) as DateChangesetPayload; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static DateChangesetPayload create() => DateChangesetPayload._();
  DateChangesetPayload createEmptyInstance() => create();
  static $pb.PbList<DateChangesetPayload> createRepeated() => $pb.PbList<DateChangesetPayload>();
  @$core.pragma('dart2js:noInline')
  static DateChangesetPayload getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<DateChangesetPayload>(create);
  static DateChangesetPayload? _defaultInstance;

  DateChangesetPayload_OneOfDate whichOneOfDate() => _DateChangesetPayload_OneOfDateByTag[$_whichOneof(0)]!;
  void clearOneOfDate() => clearField($_whichOneof(0));

  DateChangesetPayload_OneOfTime whichOneOfTime() => _DateChangesetPayload_OneOfTimeByTag[$_whichOneof(1)]!;
  void clearOneOfTime() => clearField($_whichOneof(1));

  @$pb.TagNumber(1)
  $0.CellIdentifierPayload get cellIdentifier => $_getN(0);
  @$pb.TagNumber(1)
  set cellIdentifier($0.CellIdentifierPayload v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasCellIdentifier() => $_has(0);
  @$pb.TagNumber(1)
  void clearCellIdentifier() => clearField(1);
  @$pb.TagNumber(1)
  $0.CellIdentifierPayload ensureCellIdentifier() => $_ensure(0);

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
}

