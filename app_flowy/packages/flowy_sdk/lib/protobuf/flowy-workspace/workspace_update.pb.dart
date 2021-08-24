///
//  Generated code. Do not modify.
//  source: workspace_update.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

enum UpdateWorkspaceRequest_OneOfName {
  name, 
  notSet
}

enum UpdateWorkspaceRequest_OneOfDesc {
  desc, 
  notSet
}

class UpdateWorkspaceRequest extends $pb.GeneratedMessage {
  static const $core.Map<$core.int, UpdateWorkspaceRequest_OneOfName> _UpdateWorkspaceRequest_OneOfNameByTag = {
    2 : UpdateWorkspaceRequest_OneOfName.name,
    0 : UpdateWorkspaceRequest_OneOfName.notSet
  };
  static const $core.Map<$core.int, UpdateWorkspaceRequest_OneOfDesc> _UpdateWorkspaceRequest_OneOfDescByTag = {
    3 : UpdateWorkspaceRequest_OneOfDesc.desc,
    0 : UpdateWorkspaceRequest_OneOfDesc.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'UpdateWorkspaceRequest', createEmptyInstance: create)
    ..oo(0, [2])
    ..oo(1, [3])
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'id')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'name')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'desc')
    ..hasRequiredFields = false
  ;

  UpdateWorkspaceRequest._() : super();
  factory UpdateWorkspaceRequest({
    $core.String? id,
    $core.String? name,
    $core.String? desc,
  }) {
    final _result = create();
    if (id != null) {
      _result.id = id;
    }
    if (name != null) {
      _result.name = name;
    }
    if (desc != null) {
      _result.desc = desc;
    }
    return _result;
  }
  factory UpdateWorkspaceRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory UpdateWorkspaceRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  UpdateWorkspaceRequest clone() => UpdateWorkspaceRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  UpdateWorkspaceRequest copyWith(void Function(UpdateWorkspaceRequest) updates) => super.copyWith((message) => updates(message as UpdateWorkspaceRequest)) as UpdateWorkspaceRequest; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static UpdateWorkspaceRequest create() => UpdateWorkspaceRequest._();
  UpdateWorkspaceRequest createEmptyInstance() => create();
  static $pb.PbList<UpdateWorkspaceRequest> createRepeated() => $pb.PbList<UpdateWorkspaceRequest>();
  @$core.pragma('dart2js:noInline')
  static UpdateWorkspaceRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<UpdateWorkspaceRequest>(create);
  static UpdateWorkspaceRequest? _defaultInstance;

  UpdateWorkspaceRequest_OneOfName whichOneOfName() => _UpdateWorkspaceRequest_OneOfNameByTag[$_whichOneof(0)]!;
  void clearOneOfName() => clearField($_whichOneof(0));

  UpdateWorkspaceRequest_OneOfDesc whichOneOfDesc() => _UpdateWorkspaceRequest_OneOfDescByTag[$_whichOneof(1)]!;
  void clearOneOfDesc() => clearField($_whichOneof(1));

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get desc => $_getSZ(2);
  @$pb.TagNumber(3)
  set desc($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasDesc() => $_has(2);
  @$pb.TagNumber(3)
  void clearDesc() => clearField(3);
}

enum UpdateWorkspaceParams_OneOfName {
  name, 
  notSet
}

enum UpdateWorkspaceParams_OneOfDesc {
  desc, 
  notSet
}

class UpdateWorkspaceParams extends $pb.GeneratedMessage {
  static const $core.Map<$core.int, UpdateWorkspaceParams_OneOfName> _UpdateWorkspaceParams_OneOfNameByTag = {
    2 : UpdateWorkspaceParams_OneOfName.name,
    0 : UpdateWorkspaceParams_OneOfName.notSet
  };
  static const $core.Map<$core.int, UpdateWorkspaceParams_OneOfDesc> _UpdateWorkspaceParams_OneOfDescByTag = {
    3 : UpdateWorkspaceParams_OneOfDesc.desc,
    0 : UpdateWorkspaceParams_OneOfDesc.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'UpdateWorkspaceParams', createEmptyInstance: create)
    ..oo(0, [2])
    ..oo(1, [3])
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'id')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'name')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'desc')
    ..hasRequiredFields = false
  ;

  UpdateWorkspaceParams._() : super();
  factory UpdateWorkspaceParams({
    $core.String? id,
    $core.String? name,
    $core.String? desc,
  }) {
    final _result = create();
    if (id != null) {
      _result.id = id;
    }
    if (name != null) {
      _result.name = name;
    }
    if (desc != null) {
      _result.desc = desc;
    }
    return _result;
  }
  factory UpdateWorkspaceParams.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory UpdateWorkspaceParams.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  UpdateWorkspaceParams clone() => UpdateWorkspaceParams()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  UpdateWorkspaceParams copyWith(void Function(UpdateWorkspaceParams) updates) => super.copyWith((message) => updates(message as UpdateWorkspaceParams)) as UpdateWorkspaceParams; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static UpdateWorkspaceParams create() => UpdateWorkspaceParams._();
  UpdateWorkspaceParams createEmptyInstance() => create();
  static $pb.PbList<UpdateWorkspaceParams> createRepeated() => $pb.PbList<UpdateWorkspaceParams>();
  @$core.pragma('dart2js:noInline')
  static UpdateWorkspaceParams getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<UpdateWorkspaceParams>(create);
  static UpdateWorkspaceParams? _defaultInstance;

  UpdateWorkspaceParams_OneOfName whichOneOfName() => _UpdateWorkspaceParams_OneOfNameByTag[$_whichOneof(0)]!;
  void clearOneOfName() => clearField($_whichOneof(0));

  UpdateWorkspaceParams_OneOfDesc whichOneOfDesc() => _UpdateWorkspaceParams_OneOfDescByTag[$_whichOneof(1)]!;
  void clearOneOfDesc() => clearField($_whichOneof(1));

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get desc => $_getSZ(2);
  @$pb.TagNumber(3)
  set desc($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasDesc() => $_has(2);
  @$pb.TagNumber(3)
  void clearDesc() => clearField(3);
}

