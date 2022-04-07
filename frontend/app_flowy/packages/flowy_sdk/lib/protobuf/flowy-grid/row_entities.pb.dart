///
//  Generated code. Do not modify.
//  source: row_entities.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class RowIdentifierPayload extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'RowIdentifierPayload', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'gridId')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'rowId')
    ..hasRequiredFields = false
  ;

  RowIdentifierPayload._() : super();
  factory RowIdentifierPayload({
    $core.String? gridId,
    $core.String? rowId,
  }) {
    final _result = create();
    if (gridId != null) {
      _result.gridId = gridId;
    }
    if (rowId != null) {
      _result.rowId = rowId;
    }
    return _result;
  }
  factory RowIdentifierPayload.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory RowIdentifierPayload.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  RowIdentifierPayload clone() => RowIdentifierPayload()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  RowIdentifierPayload copyWith(void Function(RowIdentifierPayload) updates) => super.copyWith((message) => updates(message as RowIdentifierPayload)) as RowIdentifierPayload; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static RowIdentifierPayload create() => RowIdentifierPayload._();
  RowIdentifierPayload createEmptyInstance() => create();
  static $pb.PbList<RowIdentifierPayload> createRepeated() => $pb.PbList<RowIdentifierPayload>();
  @$core.pragma('dart2js:noInline')
  static RowIdentifierPayload getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RowIdentifierPayload>(create);
  static RowIdentifierPayload? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get gridId => $_getSZ(0);
  @$pb.TagNumber(1)
  set gridId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasGridId() => $_has(0);
  @$pb.TagNumber(1)
  void clearGridId() => clearField(1);

  @$pb.TagNumber(3)
  $core.String get rowId => $_getSZ(1);
  @$pb.TagNumber(3)
  set rowId($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(3)
  $core.bool hasRowId() => $_has(1);
  @$pb.TagNumber(3)
  void clearRowId() => clearField(3);
}

