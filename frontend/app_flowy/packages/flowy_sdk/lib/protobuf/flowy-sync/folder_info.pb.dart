///
//  Generated code. Do not modify.
//  source: folder_info.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

class FolderInfo extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'FolderInfo', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'folderId')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'text')
    ..aInt64(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'revId')
    ..aInt64(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'baseRevId')
    ..hasRequiredFields = false
  ;

  FolderInfo._() : super();
  factory FolderInfo({
    $core.String? folderId,
    $core.String? text,
    $fixnum.Int64? revId,
    $fixnum.Int64? baseRevId,
  }) {
    final _result = create();
    if (folderId != null) {
      _result.folderId = folderId;
    }
    if (text != null) {
      _result.text = text;
    }
    if (revId != null) {
      _result.revId = revId;
    }
    if (baseRevId != null) {
      _result.baseRevId = baseRevId;
    }
    return _result;
  }
  factory FolderInfo.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory FolderInfo.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  FolderInfo clone() => FolderInfo()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  FolderInfo copyWith(void Function(FolderInfo) updates) => super.copyWith((message) => updates(message as FolderInfo)) as FolderInfo; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static FolderInfo create() => FolderInfo._();
  FolderInfo createEmptyInstance() => create();
  static $pb.PbList<FolderInfo> createRepeated() => $pb.PbList<FolderInfo>();
  @$core.pragma('dart2js:noInline')
  static FolderInfo getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<FolderInfo>(create);
  static FolderInfo? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get folderId => $_getSZ(0);
  @$pb.TagNumber(1)
  set folderId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasFolderId() => $_has(0);
  @$pb.TagNumber(1)
  void clearFolderId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get text => $_getSZ(1);
  @$pb.TagNumber(2)
  set text($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasText() => $_has(1);
  @$pb.TagNumber(2)
  void clearText() => clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get revId => $_getI64(2);
  @$pb.TagNumber(3)
  set revId($fixnum.Int64 v) { $_setInt64(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasRevId() => $_has(2);
  @$pb.TagNumber(3)
  void clearRevId() => clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get baseRevId => $_getI64(3);
  @$pb.TagNumber(4)
  set baseRevId($fixnum.Int64 v) { $_setInt64(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasBaseRevId() => $_has(3);
  @$pb.TagNumber(4)
  void clearBaseRevId() => clearField(4);
}

