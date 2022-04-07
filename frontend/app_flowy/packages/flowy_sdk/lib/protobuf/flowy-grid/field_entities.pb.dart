///
//  Generated code. Do not modify.
//  source: field_entities.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class FieldIdentifierPayload extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'FieldIdentifierPayload', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'fieldId')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'gridId')
    ..hasRequiredFields = false
  ;

  FieldIdentifierPayload._() : super();
  factory FieldIdentifierPayload({
    $core.String? fieldId,
    $core.String? gridId,
  }) {
    final _result = create();
    if (fieldId != null) {
      _result.fieldId = fieldId;
    }
    if (gridId != null) {
      _result.gridId = gridId;
    }
    return _result;
  }
  factory FieldIdentifierPayload.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory FieldIdentifierPayload.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  FieldIdentifierPayload clone() => FieldIdentifierPayload()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  FieldIdentifierPayload copyWith(void Function(FieldIdentifierPayload) updates) => super.copyWith((message) => updates(message as FieldIdentifierPayload)) as FieldIdentifierPayload; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static FieldIdentifierPayload create() => FieldIdentifierPayload._();
  FieldIdentifierPayload createEmptyInstance() => create();
  static $pb.PbList<FieldIdentifierPayload> createRepeated() => $pb.PbList<FieldIdentifierPayload>();
  @$core.pragma('dart2js:noInline')
  static FieldIdentifierPayload getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<FieldIdentifierPayload>(create);
  static FieldIdentifierPayload? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get fieldId => $_getSZ(0);
  @$pb.TagNumber(1)
  set fieldId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasFieldId() => $_has(0);
  @$pb.TagNumber(1)
  void clearFieldId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get gridId => $_getSZ(1);
  @$pb.TagNumber(2)
  set gridId($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasGridId() => $_has(1);
  @$pb.TagNumber(2)
  void clearGridId() => clearField(2);
}

