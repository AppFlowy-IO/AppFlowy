///
//  Generated code. Do not modify.
//  source: view_info.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'view.pb.dart' as $0;

import 'view.pbenum.dart' as $0;

class ViewInfoPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'ViewInfoPB', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'id')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'belongToId')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'name')
    ..aOS(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'desc')
    ..e<$0.ViewDataFormatPB>(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'dataType', $pb.PbFieldType.OE, defaultOrMaker: $0.ViewDataFormatPB.DeltaFormat, valueOf: $0.ViewDataFormatPB.valueOf, enumValues: $0.ViewDataFormatPB.values)
    ..aOM<$0.RepeatedViewPB>(6, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'belongings', subBuilder: $0.RepeatedViewPB.create)
    ..aOS(7, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'extData')
    ..hasRequiredFields = false
  ;

  ViewInfoPB._() : super();
  factory ViewInfoPB({
    $core.String? id,
    $core.String? belongToId,
    $core.String? name,
    $core.String? desc,
    $0.ViewDataFormatPB? dataType,
    $0.RepeatedViewPB? belongings,
    $core.String? extData,
  }) {
    final _result = create();
    if (id != null) {
      _result.id = id;
    }
    if (belongToId != null) {
      _result.belongToId = belongToId;
    }
    if (name != null) {
      _result.name = name;
    }
    if (desc != null) {
      _result.desc = desc;
    }
    if (dataType != null) {
      _result.dataType = dataType;
    }
    if (belongings != null) {
      _result.belongings = belongings;
    }
    if (extData != null) {
      _result.extData = extData;
    }
    return _result;
  }
  factory ViewInfoPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ViewInfoPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ViewInfoPB clone() => ViewInfoPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ViewInfoPB copyWith(void Function(ViewInfoPB) updates) => super.copyWith((message) => updates(message as ViewInfoPB)) as ViewInfoPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static ViewInfoPB create() => ViewInfoPB._();
  ViewInfoPB createEmptyInstance() => create();
  static $pb.PbList<ViewInfoPB> createRepeated() => $pb.PbList<ViewInfoPB>();
  @$core.pragma('dart2js:noInline')
  static ViewInfoPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ViewInfoPB>(create);
  static ViewInfoPB? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get belongToId => $_getSZ(1);
  @$pb.TagNumber(2)
  set belongToId($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasBelongToId() => $_has(1);
  @$pb.TagNumber(2)
  void clearBelongToId() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get name => $_getSZ(2);
  @$pb.TagNumber(3)
  set name($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasName() => $_has(2);
  @$pb.TagNumber(3)
  void clearName() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get desc => $_getSZ(3);
  @$pb.TagNumber(4)
  set desc($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasDesc() => $_has(3);
  @$pb.TagNumber(4)
  void clearDesc() => clearField(4);

  @$pb.TagNumber(5)
  $0.ViewDataFormatPB get dataType => $_getN(4);
  @$pb.TagNumber(5)
  set dataType($0.ViewDataFormatPB v) { setField(5, v); }
  @$pb.TagNumber(5)
  $core.bool hasDataType() => $_has(4);
  @$pb.TagNumber(5)
  void clearDataType() => clearField(5);

  @$pb.TagNumber(6)
  $0.RepeatedViewPB get belongings => $_getN(5);
  @$pb.TagNumber(6)
  set belongings($0.RepeatedViewPB v) { setField(6, v); }
  @$pb.TagNumber(6)
  $core.bool hasBelongings() => $_has(5);
  @$pb.TagNumber(6)
  void clearBelongings() => clearField(6);
  @$pb.TagNumber(6)
  $0.RepeatedViewPB ensureBelongings() => $_ensure(5);

  @$pb.TagNumber(7)
  $core.String get extData => $_getSZ(6);
  @$pb.TagNumber(7)
  set extData($core.String v) { $_setString(6, v); }
  @$pb.TagNumber(7)
  $core.bool hasExtData() => $_has(6);
  @$pb.TagNumber(7)
  void clearExtData() => clearField(7);
}

