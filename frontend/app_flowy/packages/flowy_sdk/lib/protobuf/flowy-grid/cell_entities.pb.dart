///
//  Generated code. Do not modify.
//  source: cell_entities.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'field_entities.pb.dart' as $0;

class CreateSelectOptionPayload extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'CreateSelectOptionPayload', createEmptyInstance: create)
    ..aOM<$0.FieldIdentifierPayload>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'fieldIdentifier', subBuilder: $0.FieldIdentifierPayload.create)
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'optionName')
    ..hasRequiredFields = false
  ;

  CreateSelectOptionPayload._() : super();
  factory CreateSelectOptionPayload({
    $0.FieldIdentifierPayload? fieldIdentifier,
    $core.String? optionName,
  }) {
    final _result = create();
    if (fieldIdentifier != null) {
      _result.fieldIdentifier = fieldIdentifier;
    }
    if (optionName != null) {
      _result.optionName = optionName;
    }
    return _result;
  }
  factory CreateSelectOptionPayload.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory CreateSelectOptionPayload.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  CreateSelectOptionPayload clone() => CreateSelectOptionPayload()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  CreateSelectOptionPayload copyWith(void Function(CreateSelectOptionPayload) updates) => super.copyWith((message) => updates(message as CreateSelectOptionPayload)) as CreateSelectOptionPayload; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static CreateSelectOptionPayload create() => CreateSelectOptionPayload._();
  CreateSelectOptionPayload createEmptyInstance() => create();
  static $pb.PbList<CreateSelectOptionPayload> createRepeated() => $pb.PbList<CreateSelectOptionPayload>();
  @$core.pragma('dart2js:noInline')
  static CreateSelectOptionPayload getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CreateSelectOptionPayload>(create);
  static CreateSelectOptionPayload? _defaultInstance;

  @$pb.TagNumber(1)
  $0.FieldIdentifierPayload get fieldIdentifier => $_getN(0);
  @$pb.TagNumber(1)
  set fieldIdentifier($0.FieldIdentifierPayload v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasFieldIdentifier() => $_has(0);
  @$pb.TagNumber(1)
  void clearFieldIdentifier() => clearField(1);
  @$pb.TagNumber(1)
  $0.FieldIdentifierPayload ensureFieldIdentifier() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.String get optionName => $_getSZ(1);
  @$pb.TagNumber(2)
  set optionName($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasOptionName() => $_has(1);
  @$pb.TagNumber(2)
  void clearOptionName() => clearField(2);
}

class CellIdentifierPayload extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'CellIdentifierPayload', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'gridId')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'fieldId')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'rowId')
    ..hasRequiredFields = false
  ;

  CellIdentifierPayload._() : super();
  factory CellIdentifierPayload({
    $core.String? gridId,
    $core.String? fieldId,
    $core.String? rowId,
  }) {
    final _result = create();
    if (gridId != null) {
      _result.gridId = gridId;
    }
    if (fieldId != null) {
      _result.fieldId = fieldId;
    }
    if (rowId != null) {
      _result.rowId = rowId;
    }
    return _result;
  }
  factory CellIdentifierPayload.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory CellIdentifierPayload.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  CellIdentifierPayload clone() => CellIdentifierPayload()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  CellIdentifierPayload copyWith(void Function(CellIdentifierPayload) updates) => super.copyWith((message) => updates(message as CellIdentifierPayload)) as CellIdentifierPayload; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static CellIdentifierPayload create() => CellIdentifierPayload._();
  CellIdentifierPayload createEmptyInstance() => create();
  static $pb.PbList<CellIdentifierPayload> createRepeated() => $pb.PbList<CellIdentifierPayload>();
  @$core.pragma('dart2js:noInline')
  static CellIdentifierPayload getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CellIdentifierPayload>(create);
  static CellIdentifierPayload? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get gridId => $_getSZ(0);
  @$pb.TagNumber(1)
  set gridId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasGridId() => $_has(0);
  @$pb.TagNumber(1)
  void clearGridId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get fieldId => $_getSZ(1);
  @$pb.TagNumber(2)
  set fieldId($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasFieldId() => $_has(1);
  @$pb.TagNumber(2)
  void clearFieldId() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get rowId => $_getSZ(2);
  @$pb.TagNumber(3)
  set rowId($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasRowId() => $_has(2);
  @$pb.TagNumber(3)
  void clearRowId() => clearField(3);
}

