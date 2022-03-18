///
//  Generated code. Do not modify.
//  source: date_description.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'date_description.pbenum.dart';

export 'date_description.pbenum.dart';

class DateDescription extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'DateDescription', createEmptyInstance: create)
    ..e<DateFormat>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'dateFormat', $pb.PbFieldType.OE, defaultOrMaker: DateFormat.Local, valueOf: DateFormat.valueOf, enumValues: DateFormat.values)
    ..e<TimeFormat>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'timeFormat', $pb.PbFieldType.OE, defaultOrMaker: TimeFormat.TwelveHour, valueOf: TimeFormat.valueOf, enumValues: TimeFormat.values)
    ..hasRequiredFields = false
  ;

  DateDescription._() : super();
  factory DateDescription({
    DateFormat? dateFormat,
    TimeFormat? timeFormat,
  }) {
    final _result = create();
    if (dateFormat != null) {
      _result.dateFormat = dateFormat;
    }
    if (timeFormat != null) {
      _result.timeFormat = timeFormat;
    }
    return _result;
  }
  factory DateDescription.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory DateDescription.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  DateDescription clone() => DateDescription()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  DateDescription copyWith(void Function(DateDescription) updates) => super.copyWith((message) => updates(message as DateDescription)) as DateDescription; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static DateDescription create() => DateDescription._();
  DateDescription createEmptyInstance() => create();
  static $pb.PbList<DateDescription> createRepeated() => $pb.PbList<DateDescription>();
  @$core.pragma('dart2js:noInline')
  static DateDescription getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<DateDescription>(create);
  static DateDescription? _defaultInstance;

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
}

