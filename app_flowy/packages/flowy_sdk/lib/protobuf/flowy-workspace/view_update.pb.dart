///
//  Generated code. Do not modify.
//  source: view_update.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

enum UpdateViewRequest_OneOfName {
  name, 
  notSet
}

enum UpdateViewRequest_OneOfDesc {
  desc, 
  notSet
}

enum UpdateViewRequest_OneOfThumbnail {
  thumbnail, 
  notSet
}

enum UpdateViewRequest_OneOfIsTrash {
  isTrash, 
  notSet
}

class UpdateViewRequest extends $pb.GeneratedMessage {
  static const $core.Map<$core.int, UpdateViewRequest_OneOfName> _UpdateViewRequest_OneOfNameByTag = {
    2 : UpdateViewRequest_OneOfName.name,
    0 : UpdateViewRequest_OneOfName.notSet
  };
  static const $core.Map<$core.int, UpdateViewRequest_OneOfDesc> _UpdateViewRequest_OneOfDescByTag = {
    3 : UpdateViewRequest_OneOfDesc.desc,
    0 : UpdateViewRequest_OneOfDesc.notSet
  };
  static const $core.Map<$core.int, UpdateViewRequest_OneOfThumbnail> _UpdateViewRequest_OneOfThumbnailByTag = {
    4 : UpdateViewRequest_OneOfThumbnail.thumbnail,
    0 : UpdateViewRequest_OneOfThumbnail.notSet
  };
  static const $core.Map<$core.int, UpdateViewRequest_OneOfIsTrash> _UpdateViewRequest_OneOfIsTrashByTag = {
    5 : UpdateViewRequest_OneOfIsTrash.isTrash,
    0 : UpdateViewRequest_OneOfIsTrash.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'UpdateViewRequest', createEmptyInstance: create)
    ..oo(0, [2])
    ..oo(1, [3])
    ..oo(2, [4])
    ..oo(3, [5])
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'viewId')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'name')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'desc')
    ..aOS(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'thumbnail')
    ..aOB(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'isTrash')
    ..hasRequiredFields = false
  ;

  UpdateViewRequest._() : super();
  factory UpdateViewRequest({
    $core.String? viewId,
    $core.String? name,
    $core.String? desc,
    $core.String? thumbnail,
    $core.bool? isTrash,
  }) {
    final _result = create();
    if (viewId != null) {
      _result.viewId = viewId;
    }
    if (name != null) {
      _result.name = name;
    }
    if (desc != null) {
      _result.desc = desc;
    }
    if (thumbnail != null) {
      _result.thumbnail = thumbnail;
    }
    if (isTrash != null) {
      _result.isTrash = isTrash;
    }
    return _result;
  }
  factory UpdateViewRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory UpdateViewRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  UpdateViewRequest clone() => UpdateViewRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  UpdateViewRequest copyWith(void Function(UpdateViewRequest) updates) => super.copyWith((message) => updates(message as UpdateViewRequest)) as UpdateViewRequest; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static UpdateViewRequest create() => UpdateViewRequest._();
  UpdateViewRequest createEmptyInstance() => create();
  static $pb.PbList<UpdateViewRequest> createRepeated() => $pb.PbList<UpdateViewRequest>();
  @$core.pragma('dart2js:noInline')
  static UpdateViewRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<UpdateViewRequest>(create);
  static UpdateViewRequest? _defaultInstance;

  UpdateViewRequest_OneOfName whichOneOfName() => _UpdateViewRequest_OneOfNameByTag[$_whichOneof(0)]!;
  void clearOneOfName() => clearField($_whichOneof(0));

  UpdateViewRequest_OneOfDesc whichOneOfDesc() => _UpdateViewRequest_OneOfDescByTag[$_whichOneof(1)]!;
  void clearOneOfDesc() => clearField($_whichOneof(1));

  UpdateViewRequest_OneOfThumbnail whichOneOfThumbnail() => _UpdateViewRequest_OneOfThumbnailByTag[$_whichOneof(2)]!;
  void clearOneOfThumbnail() => clearField($_whichOneof(2));

  UpdateViewRequest_OneOfIsTrash whichOneOfIsTrash() => _UpdateViewRequest_OneOfIsTrashByTag[$_whichOneof(3)]!;
  void clearOneOfIsTrash() => clearField($_whichOneof(3));

  @$pb.TagNumber(1)
  $core.String get viewId => $_getSZ(0);
  @$pb.TagNumber(1)
  set viewId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasViewId() => $_has(0);
  @$pb.TagNumber(1)
  void clearViewId() => clearField(1);

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

  @$pb.TagNumber(4)
  $core.String get thumbnail => $_getSZ(3);
  @$pb.TagNumber(4)
  set thumbnail($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasThumbnail() => $_has(3);
  @$pb.TagNumber(4)
  void clearThumbnail() => clearField(4);

  @$pb.TagNumber(5)
  $core.bool get isTrash => $_getBF(4);
  @$pb.TagNumber(5)
  set isTrash($core.bool v) { $_setBool(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasIsTrash() => $_has(4);
  @$pb.TagNumber(5)
  void clearIsTrash() => clearField(5);
}

enum UpdateViewParams_OneOfName {
  name, 
  notSet
}

enum UpdateViewParams_OneOfDesc {
  desc, 
  notSet
}

enum UpdateViewParams_OneOfThumbnail {
  thumbnail, 
  notSet
}

enum UpdateViewParams_OneOfIsTrash {
  isTrash, 
  notSet
}

class UpdateViewParams extends $pb.GeneratedMessage {
  static const $core.Map<$core.int, UpdateViewParams_OneOfName> _UpdateViewParams_OneOfNameByTag = {
    2 : UpdateViewParams_OneOfName.name,
    0 : UpdateViewParams_OneOfName.notSet
  };
  static const $core.Map<$core.int, UpdateViewParams_OneOfDesc> _UpdateViewParams_OneOfDescByTag = {
    3 : UpdateViewParams_OneOfDesc.desc,
    0 : UpdateViewParams_OneOfDesc.notSet
  };
  static const $core.Map<$core.int, UpdateViewParams_OneOfThumbnail> _UpdateViewParams_OneOfThumbnailByTag = {
    4 : UpdateViewParams_OneOfThumbnail.thumbnail,
    0 : UpdateViewParams_OneOfThumbnail.notSet
  };
  static const $core.Map<$core.int, UpdateViewParams_OneOfIsTrash> _UpdateViewParams_OneOfIsTrashByTag = {
    5 : UpdateViewParams_OneOfIsTrash.isTrash,
    0 : UpdateViewParams_OneOfIsTrash.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'UpdateViewParams', createEmptyInstance: create)
    ..oo(0, [2])
    ..oo(1, [3])
    ..oo(2, [4])
    ..oo(3, [5])
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'viewId')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'name')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'desc')
    ..aOS(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'thumbnail')
    ..aOB(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'isTrash')
    ..hasRequiredFields = false
  ;

  UpdateViewParams._() : super();
  factory UpdateViewParams({
    $core.String? viewId,
    $core.String? name,
    $core.String? desc,
    $core.String? thumbnail,
    $core.bool? isTrash,
  }) {
    final _result = create();
    if (viewId != null) {
      _result.viewId = viewId;
    }
    if (name != null) {
      _result.name = name;
    }
    if (desc != null) {
      _result.desc = desc;
    }
    if (thumbnail != null) {
      _result.thumbnail = thumbnail;
    }
    if (isTrash != null) {
      _result.isTrash = isTrash;
    }
    return _result;
  }
  factory UpdateViewParams.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory UpdateViewParams.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  UpdateViewParams clone() => UpdateViewParams()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  UpdateViewParams copyWith(void Function(UpdateViewParams) updates) => super.copyWith((message) => updates(message as UpdateViewParams)) as UpdateViewParams; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static UpdateViewParams create() => UpdateViewParams._();
  UpdateViewParams createEmptyInstance() => create();
  static $pb.PbList<UpdateViewParams> createRepeated() => $pb.PbList<UpdateViewParams>();
  @$core.pragma('dart2js:noInline')
  static UpdateViewParams getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<UpdateViewParams>(create);
  static UpdateViewParams? _defaultInstance;

  UpdateViewParams_OneOfName whichOneOfName() => _UpdateViewParams_OneOfNameByTag[$_whichOneof(0)]!;
  void clearOneOfName() => clearField($_whichOneof(0));

  UpdateViewParams_OneOfDesc whichOneOfDesc() => _UpdateViewParams_OneOfDescByTag[$_whichOneof(1)]!;
  void clearOneOfDesc() => clearField($_whichOneof(1));

  UpdateViewParams_OneOfThumbnail whichOneOfThumbnail() => _UpdateViewParams_OneOfThumbnailByTag[$_whichOneof(2)]!;
  void clearOneOfThumbnail() => clearField($_whichOneof(2));

  UpdateViewParams_OneOfIsTrash whichOneOfIsTrash() => _UpdateViewParams_OneOfIsTrashByTag[$_whichOneof(3)]!;
  void clearOneOfIsTrash() => clearField($_whichOneof(3));

  @$pb.TagNumber(1)
  $core.String get viewId => $_getSZ(0);
  @$pb.TagNumber(1)
  set viewId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasViewId() => $_has(0);
  @$pb.TagNumber(1)
  void clearViewId() => clearField(1);

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

  @$pb.TagNumber(4)
  $core.String get thumbnail => $_getSZ(3);
  @$pb.TagNumber(4)
  set thumbnail($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasThumbnail() => $_has(3);
  @$pb.TagNumber(4)
  void clearThumbnail() => clearField(4);

  @$pb.TagNumber(5)
  $core.bool get isTrash => $_getBF(4);
  @$pb.TagNumber(5)
  set isTrash($core.bool v) { $_setBool(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasIsTrash() => $_has(4);
  @$pb.TagNumber(5)
  void clearIsTrash() => clearField(5);
}

class SaveViewDataRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'SaveViewDataRequest', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'viewId')
    ..a<$core.List<$core.int>>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'data', $pb.PbFieldType.OY)
    ..hasRequiredFields = false
  ;

  SaveViewDataRequest._() : super();
  factory SaveViewDataRequest({
    $core.String? viewId,
    $core.List<$core.int>? data,
  }) {
    final _result = create();
    if (viewId != null) {
      _result.viewId = viewId;
    }
    if (data != null) {
      _result.data = data;
    }
    return _result;
  }
  factory SaveViewDataRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory SaveViewDataRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  SaveViewDataRequest clone() => SaveViewDataRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  SaveViewDataRequest copyWith(void Function(SaveViewDataRequest) updates) => super.copyWith((message) => updates(message as SaveViewDataRequest)) as SaveViewDataRequest; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static SaveViewDataRequest create() => SaveViewDataRequest._();
  SaveViewDataRequest createEmptyInstance() => create();
  static $pb.PbList<SaveViewDataRequest> createRepeated() => $pb.PbList<SaveViewDataRequest>();
  @$core.pragma('dart2js:noInline')
  static SaveViewDataRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SaveViewDataRequest>(create);
  static SaveViewDataRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get viewId => $_getSZ(0);
  @$pb.TagNumber(1)
  set viewId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasViewId() => $_has(0);
  @$pb.TagNumber(1)
  void clearViewId() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get data => $_getN(1);
  @$pb.TagNumber(2)
  set data($core.List<$core.int> v) { $_setBytes(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasData() => $_has(1);
  @$pb.TagNumber(2)
  void clearData() => clearField(2);
}

class ApplyChangesetRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'ApplyChangesetRequest', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'viewId')
    ..a<$core.List<$core.int>>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'data', $pb.PbFieldType.OY)
    ..hasRequiredFields = false
  ;

  ApplyChangesetRequest._() : super();
  factory ApplyChangesetRequest({
    $core.String? viewId,
    $core.List<$core.int>? data,
  }) {
    final _result = create();
    if (viewId != null) {
      _result.viewId = viewId;
    }
    if (data != null) {
      _result.data = data;
    }
    return _result;
  }
  factory ApplyChangesetRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ApplyChangesetRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ApplyChangesetRequest clone() => ApplyChangesetRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ApplyChangesetRequest copyWith(void Function(ApplyChangesetRequest) updates) => super.copyWith((message) => updates(message as ApplyChangesetRequest)) as ApplyChangesetRequest; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static ApplyChangesetRequest create() => ApplyChangesetRequest._();
  ApplyChangesetRequest createEmptyInstance() => create();
  static $pb.PbList<ApplyChangesetRequest> createRepeated() => $pb.PbList<ApplyChangesetRequest>();
  @$core.pragma('dart2js:noInline')
  static ApplyChangesetRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ApplyChangesetRequest>(create);
  static ApplyChangesetRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get viewId => $_getSZ(0);
  @$pb.TagNumber(1)
  set viewId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasViewId() => $_has(0);
  @$pb.TagNumber(1)
  void clearViewId() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get data => $_getN(1);
  @$pb.TagNumber(2)
  set data($core.List<$core.int> v) { $_setBytes(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasData() => $_has(1);
  @$pb.TagNumber(2)
  void clearData() => clearField(2);
}

