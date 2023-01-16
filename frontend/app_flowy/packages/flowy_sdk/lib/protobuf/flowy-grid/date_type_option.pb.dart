///
//  Generated code. Do not modify.
//  source: date_type_option.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'date_type_option_entities.pbenum.dart' as $0;

class DateTypeOptionPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'DateTypeOptionPB', createEmptyInstance: create)
    ..e<$0.DateFormat>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'dateFormat', $pb.PbFieldType.OE, defaultOrMaker: $0.DateFormat.Local, valueOf: $0.DateFormat.valueOf, enumValues: $0.DateFormat.values)
    ..e<$0.TimeFormat>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'timeFormat', $pb.PbFieldType.OE, defaultOrMaker: $0.TimeFormat.TwelveHour, valueOf: $0.TimeFormat.valueOf, enumValues: $0.TimeFormat.values)
    ..aOB(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'includeTime')
    ..hasRequiredFields = false
  ;

  DateTypeOptionPB._() : super();
  factory DateTypeOptionPB({
    $0.DateFormat? dateFormat,
    $0.TimeFormat? timeFormat,
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
  factory DateTypeOptionPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory DateTypeOptionPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  DateTypeOptionPB clone() => DateTypeOptionPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  DateTypeOptionPB copyWith(void Function(DateTypeOptionPB) updates) => super.copyWith((message) => updates(message as DateTypeOptionPB)) as DateTypeOptionPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static DateTypeOptionPB create() => DateTypeOptionPB._();
  DateTypeOptionPB createEmptyInstance() => create();
  static $pb.PbList<DateTypeOptionPB> createRepeated() => $pb.PbList<DateTypeOptionPB>();
  @$core.pragma('dart2js:noInline')
  static DateTypeOptionPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<DateTypeOptionPB>(create);
  static DateTypeOptionPB? _defaultInstance;

  @$pb.TagNumber(1)
  $0.DateFormat get dateFormat => $_getN(0);
  @$pb.TagNumber(1)
  set dateFormat($0.DateFormat v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasDateFormat() => $_has(0);
  @$pb.TagNumber(1)
  void clearDateFormat() => clearField(1);

  @$pb.TagNumber(2)
  $0.TimeFormat get timeFormat => $_getN(1);
  @$pb.TagNumber(2)
  set timeFormat($0.TimeFormat v) { setField(2, v); }
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

