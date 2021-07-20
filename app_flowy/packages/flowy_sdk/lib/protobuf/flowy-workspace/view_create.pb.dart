///
//  Generated code. Do not modify.
//  source: view_create.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'view_create.pbenum.dart';

export 'view_create.pbenum.dart';

enum CreateViewRequest_OneOfThumbnail {
  thumbnail, 
  notSet
}

class CreateViewRequest extends $pb.GeneratedMessage {
  static const $core.Map<$core.int, CreateViewRequest_OneOfThumbnail> _CreateViewRequest_OneOfThumbnailByTag = {
    4 : CreateViewRequest_OneOfThumbnail.thumbnail,
    0 : CreateViewRequest_OneOfThumbnail.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'CreateViewRequest', createEmptyInstance: create)
    ..oo(0, [4])
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'appId')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'name')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'desc')
    ..aOS(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'thumbnail')
    ..e<ViewTypeIdentifier>(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'viewType', $pb.PbFieldType.OE, defaultOrMaker: ViewTypeIdentifier.Docs, valueOf: ViewTypeIdentifier.valueOf, enumValues: ViewTypeIdentifier.values)
    ..hasRequiredFields = false
  ;

  CreateViewRequest._() : super();
  factory CreateViewRequest({
    $core.String? appId,
    $core.String? name,
    $core.String? desc,
    $core.String? thumbnail,
    ViewTypeIdentifier? viewType,
  }) {
    final _result = create();
    if (appId != null) {
      _result.appId = appId;
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
    if (viewType != null) {
      _result.viewType = viewType;
    }
    return _result;
  }
  factory CreateViewRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory CreateViewRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  CreateViewRequest clone() => CreateViewRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  CreateViewRequest copyWith(void Function(CreateViewRequest) updates) => super.copyWith((message) => updates(message as CreateViewRequest)) as CreateViewRequest; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static CreateViewRequest create() => CreateViewRequest._();
  CreateViewRequest createEmptyInstance() => create();
  static $pb.PbList<CreateViewRequest> createRepeated() => $pb.PbList<CreateViewRequest>();
  @$core.pragma('dart2js:noInline')
  static CreateViewRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CreateViewRequest>(create);
  static CreateViewRequest? _defaultInstance;

  CreateViewRequest_OneOfThumbnail whichOneOfThumbnail() => _CreateViewRequest_OneOfThumbnailByTag[$_whichOneof(0)]!;
  void clearOneOfThumbnail() => clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $core.String get appId => $_getSZ(0);
  @$pb.TagNumber(1)
  set appId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasAppId() => $_has(0);
  @$pb.TagNumber(1)
  void clearAppId() => clearField(1);

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
  ViewTypeIdentifier get viewType => $_getN(4);
  @$pb.TagNumber(5)
  set viewType(ViewTypeIdentifier v) { setField(5, v); }
  @$pb.TagNumber(5)
  $core.bool hasViewType() => $_has(4);
  @$pb.TagNumber(5)
  void clearViewType() => clearField(5);
}

class View extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'View', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'id')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'appId')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'name')
    ..aOS(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'desc')
    ..e<ViewTypeIdentifier>(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'viewType', $pb.PbFieldType.OE, defaultOrMaker: ViewTypeIdentifier.Docs, valueOf: ViewTypeIdentifier.valueOf, enumValues: ViewTypeIdentifier.values)
    ..hasRequiredFields = false
  ;

  View._() : super();
  factory View({
    $core.String? id,
    $core.String? appId,
    $core.String? name,
    $core.String? desc,
    ViewTypeIdentifier? viewType,
  }) {
    final _result = create();
    if (id != null) {
      _result.id = id;
    }
    if (appId != null) {
      _result.appId = appId;
    }
    if (name != null) {
      _result.name = name;
    }
    if (desc != null) {
      _result.desc = desc;
    }
    if (viewType != null) {
      _result.viewType = viewType;
    }
    return _result;
  }
  factory View.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory View.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  View clone() => View()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  View copyWith(void Function(View) updates) => super.copyWith((message) => updates(message as View)) as View; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static View create() => View._();
  View createEmptyInstance() => create();
  static $pb.PbList<View> createRepeated() => $pb.PbList<View>();
  @$core.pragma('dart2js:noInline')
  static View getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<View>(create);
  static View? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get appId => $_getSZ(1);
  @$pb.TagNumber(2)
  set appId($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasAppId() => $_has(1);
  @$pb.TagNumber(2)
  void clearAppId() => clearField(2);

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
  ViewTypeIdentifier get viewType => $_getN(4);
  @$pb.TagNumber(5)
  set viewType(ViewTypeIdentifier v) { setField(5, v); }
  @$pb.TagNumber(5)
  $core.bool hasViewType() => $_has(4);
  @$pb.TagNumber(5)
  void clearViewType() => clearField(5);
}

