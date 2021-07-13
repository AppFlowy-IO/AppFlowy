///
//  Generated code. Do not modify.
//  source: app_update.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'app_create.pb.dart' as $0;

enum UpdateAppRequest_OneOfWorkspaceId {
  workspaceId, 
  notSet
}

enum UpdateAppRequest_OneOfName {
  name, 
  notSet
}

enum UpdateAppRequest_OneOfDesc {
  desc, 
  notSet
}

enum UpdateAppRequest_OneOfColorStyle {
  colorStyle, 
  notSet
}

class UpdateAppRequest extends $pb.GeneratedMessage {
  static const $core.Map<$core.int, UpdateAppRequest_OneOfWorkspaceId> _UpdateAppRequest_OneOfWorkspaceIdByTag = {
    2 : UpdateAppRequest_OneOfWorkspaceId.workspaceId,
    0 : UpdateAppRequest_OneOfWorkspaceId.notSet
  };
  static const $core.Map<$core.int, UpdateAppRequest_OneOfName> _UpdateAppRequest_OneOfNameByTag = {
    3 : UpdateAppRequest_OneOfName.name,
    0 : UpdateAppRequest_OneOfName.notSet
  };
  static const $core.Map<$core.int, UpdateAppRequest_OneOfDesc> _UpdateAppRequest_OneOfDescByTag = {
    4 : UpdateAppRequest_OneOfDesc.desc,
    0 : UpdateAppRequest_OneOfDesc.notSet
  };
  static const $core.Map<$core.int, UpdateAppRequest_OneOfColorStyle> _UpdateAppRequest_OneOfColorStyleByTag = {
    5 : UpdateAppRequest_OneOfColorStyle.colorStyle,
    0 : UpdateAppRequest_OneOfColorStyle.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'UpdateAppRequest', createEmptyInstance: create)
    ..oo(0, [2])
    ..oo(1, [3])
    ..oo(2, [4])
    ..oo(3, [5])
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'appId')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'workspaceId')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'name')
    ..aOS(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'desc')
    ..aOM<$0.ColorStyle>(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'colorStyle', subBuilder: $0.ColorStyle.create)
    ..hasRequiredFields = false
  ;

  UpdateAppRequest._() : super();
  factory UpdateAppRequest({
    $core.String? appId,
    $core.String? workspaceId,
    $core.String? name,
    $core.String? desc,
    $0.ColorStyle? colorStyle,
  }) {
    final _result = create();
    if (appId != null) {
      _result.appId = appId;
    }
    if (workspaceId != null) {
      _result.workspaceId = workspaceId;
    }
    if (name != null) {
      _result.name = name;
    }
    if (desc != null) {
      _result.desc = desc;
    }
    if (colorStyle != null) {
      _result.colorStyle = colorStyle;
    }
    return _result;
  }
  factory UpdateAppRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory UpdateAppRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  UpdateAppRequest clone() => UpdateAppRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  UpdateAppRequest copyWith(void Function(UpdateAppRequest) updates) => super.copyWith((message) => updates(message as UpdateAppRequest)) as UpdateAppRequest; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static UpdateAppRequest create() => UpdateAppRequest._();
  UpdateAppRequest createEmptyInstance() => create();
  static $pb.PbList<UpdateAppRequest> createRepeated() => $pb.PbList<UpdateAppRequest>();
  @$core.pragma('dart2js:noInline')
  static UpdateAppRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<UpdateAppRequest>(create);
  static UpdateAppRequest? _defaultInstance;

  UpdateAppRequest_OneOfWorkspaceId whichOneOfWorkspaceId() => _UpdateAppRequest_OneOfWorkspaceIdByTag[$_whichOneof(0)]!;
  void clearOneOfWorkspaceId() => clearField($_whichOneof(0));

  UpdateAppRequest_OneOfName whichOneOfName() => _UpdateAppRequest_OneOfNameByTag[$_whichOneof(1)]!;
  void clearOneOfName() => clearField($_whichOneof(1));

  UpdateAppRequest_OneOfDesc whichOneOfDesc() => _UpdateAppRequest_OneOfDescByTag[$_whichOneof(2)]!;
  void clearOneOfDesc() => clearField($_whichOneof(2));

  UpdateAppRequest_OneOfColorStyle whichOneOfColorStyle() => _UpdateAppRequest_OneOfColorStyleByTag[$_whichOneof(3)]!;
  void clearOneOfColorStyle() => clearField($_whichOneof(3));

  @$pb.TagNumber(1)
  $core.String get appId => $_getSZ(0);
  @$pb.TagNumber(1)
  set appId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasAppId() => $_has(0);
  @$pb.TagNumber(1)
  void clearAppId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get workspaceId => $_getSZ(1);
  @$pb.TagNumber(2)
  set workspaceId($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasWorkspaceId() => $_has(1);
  @$pb.TagNumber(2)
  void clearWorkspaceId() => clearField(2);

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
  $0.ColorStyle get colorStyle => $_getN(4);
  @$pb.TagNumber(5)
  set colorStyle($0.ColorStyle v) { setField(5, v); }
  @$pb.TagNumber(5)
  $core.bool hasColorStyle() => $_has(4);
  @$pb.TagNumber(5)
  void clearColorStyle() => clearField(5);
  @$pb.TagNumber(5)
  $0.ColorStyle ensureColorStyle() => $_ensure(4);
}

