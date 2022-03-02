///
//  Generated code. Do not modify.
//  source: share.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'share.pbenum.dart';

export 'share.pbenum.dart';

class ExportPayload extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'ExportPayload', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'viewId')
    ..e<ExportType>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'exportType', $pb.PbFieldType.OE, defaultOrMaker: ExportType.Text, valueOf: ExportType.valueOf, enumValues: ExportType.values)
    ..hasRequiredFields = false
  ;

  ExportPayload._() : super();
  factory ExportPayload({
    $core.String? viewId,
    ExportType? exportType,
  }) {
    final _result = create();
    if (viewId != null) {
      _result.viewId = viewId;
    }
    if (exportType != null) {
      _result.exportType = exportType;
    }
    return _result;
  }
  factory ExportPayload.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ExportPayload.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ExportPayload clone() => ExportPayload()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ExportPayload copyWith(void Function(ExportPayload) updates) => super.copyWith((message) => updates(message as ExportPayload)) as ExportPayload; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static ExportPayload create() => ExportPayload._();
  ExportPayload createEmptyInstance() => create();
  static $pb.PbList<ExportPayload> createRepeated() => $pb.PbList<ExportPayload>();
  @$core.pragma('dart2js:noInline')
  static ExportPayload getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ExportPayload>(create);
  static ExportPayload? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get viewId => $_getSZ(0);
  @$pb.TagNumber(1)
  set viewId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasViewId() => $_has(0);
  @$pb.TagNumber(1)
  void clearViewId() => clearField(1);

  @$pb.TagNumber(2)
  ExportType get exportType => $_getN(1);
  @$pb.TagNumber(2)
  set exportType(ExportType v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasExportType() => $_has(1);
  @$pb.TagNumber(2)
  void clearExportType() => clearField(2);
}

class ExportData extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'ExportData', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'data')
    ..e<ExportType>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'exportType', $pb.PbFieldType.OE, defaultOrMaker: ExportType.Text, valueOf: ExportType.valueOf, enumValues: ExportType.values)
    ..hasRequiredFields = false
  ;

  ExportData._() : super();
  factory ExportData({
    $core.String? data,
    ExportType? exportType,
  }) {
    final _result = create();
    if (data != null) {
      _result.data = data;
    }
    if (exportType != null) {
      _result.exportType = exportType;
    }
    return _result;
  }
  factory ExportData.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ExportData.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ExportData clone() => ExportData()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ExportData copyWith(void Function(ExportData) updates) => super.copyWith((message) => updates(message as ExportData)) as ExportData; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static ExportData create() => ExportData._();
  ExportData createEmptyInstance() => create();
  static $pb.PbList<ExportData> createRepeated() => $pb.PbList<ExportData>();
  @$core.pragma('dart2js:noInline')
  static ExportData getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ExportData>(create);
  static ExportData? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get data => $_getSZ(0);
  @$pb.TagNumber(1)
  set data($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasData() => $_has(0);
  @$pb.TagNumber(1)
  void clearData() => clearField(1);

  @$pb.TagNumber(2)
  ExportType get exportType => $_getN(1);
  @$pb.TagNumber(2)
  set exportType(ExportType v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasExportType() => $_has(1);
  @$pb.TagNumber(2)
  void clearExportType() => clearField(2);
}

