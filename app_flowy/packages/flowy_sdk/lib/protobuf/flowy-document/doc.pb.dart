///
//  Generated code. Do not modify.
//  source: doc.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

class CreateDocParams extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'CreateDocParams', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'id')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'data')
    ..hasRequiredFields = false
  ;

  CreateDocParams._() : super();
  factory CreateDocParams({
    $core.String? id,
    $core.String? data,
  }) {
    final _result = create();
    if (id != null) {
      _result.id = id;
    }
    if (data != null) {
      _result.data = data;
    }
    return _result;
  }
  factory CreateDocParams.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory CreateDocParams.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  CreateDocParams clone() => CreateDocParams()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  CreateDocParams copyWith(void Function(CreateDocParams) updates) => super.copyWith((message) => updates(message as CreateDocParams)) as CreateDocParams; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static CreateDocParams create() => CreateDocParams._();
  CreateDocParams createEmptyInstance() => create();
  static $pb.PbList<CreateDocParams> createRepeated() => $pb.PbList<CreateDocParams>();
  @$core.pragma('dart2js:noInline')
  static CreateDocParams getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CreateDocParams>(create);
  static CreateDocParams? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get data => $_getSZ(1);
  @$pb.TagNumber(2)
  set data($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasData() => $_has(1);
  @$pb.TagNumber(2)
  void clearData() => clearField(2);
}

class Doc extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'Doc', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'id')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'data')
    ..aInt64(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'revId')
    ..aInt64(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'baseRevId')
    ..hasRequiredFields = false
  ;

  Doc._() : super();
  factory Doc({
    $core.String? id,
    $core.String? data,
    $fixnum.Int64? revId,
    $fixnum.Int64? baseRevId,
  }) {
    final _result = create();
    if (id != null) {
      _result.id = id;
    }
    if (data != null) {
      _result.data = data;
    }
    if (revId != null) {
      _result.revId = revId;
    }
    if (baseRevId != null) {
      _result.baseRevId = baseRevId;
    }
    return _result;
  }
  factory Doc.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Doc.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Doc clone() => Doc()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Doc copyWith(void Function(Doc) updates) => super.copyWith((message) => updates(message as Doc)) as Doc; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static Doc create() => Doc._();
  Doc createEmptyInstance() => create();
  static $pb.PbList<Doc> createRepeated() => $pb.PbList<Doc>();
  @$core.pragma('dart2js:noInline')
  static Doc getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Doc>(create);
  static Doc? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get data => $_getSZ(1);
  @$pb.TagNumber(2)
  set data($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasData() => $_has(1);
  @$pb.TagNumber(2)
  void clearData() => clearField(2);

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

class UpdateDocParams extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'UpdateDocParams', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'docId')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'data')
    ..aInt64(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'revId')
    ..hasRequiredFields = false
  ;

  UpdateDocParams._() : super();
  factory UpdateDocParams({
    $core.String? docId,
    $core.String? data,
    $fixnum.Int64? revId,
  }) {
    final _result = create();
    if (docId != null) {
      _result.docId = docId;
    }
    if (data != null) {
      _result.data = data;
    }
    if (revId != null) {
      _result.revId = revId;
    }
    return _result;
  }
  factory UpdateDocParams.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory UpdateDocParams.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  UpdateDocParams clone() => UpdateDocParams()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  UpdateDocParams copyWith(void Function(UpdateDocParams) updates) => super.copyWith((message) => updates(message as UpdateDocParams)) as UpdateDocParams; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static UpdateDocParams create() => UpdateDocParams._();
  UpdateDocParams createEmptyInstance() => create();
  static $pb.PbList<UpdateDocParams> createRepeated() => $pb.PbList<UpdateDocParams>();
  @$core.pragma('dart2js:noInline')
  static UpdateDocParams getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<UpdateDocParams>(create);
  static UpdateDocParams? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get docId => $_getSZ(0);
  @$pb.TagNumber(1)
  set docId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasDocId() => $_has(0);
  @$pb.TagNumber(1)
  void clearDocId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get data => $_getSZ(1);
  @$pb.TagNumber(2)
  set data($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasData() => $_has(1);
  @$pb.TagNumber(2)
  void clearData() => clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get revId => $_getI64(2);
  @$pb.TagNumber(3)
  set revId($fixnum.Int64 v) { $_setInt64(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasRevId() => $_has(2);
  @$pb.TagNumber(3)
  void clearRevId() => clearField(3);
}

class DocDelta extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'DocDelta', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'docId')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'data')
    ..hasRequiredFields = false
  ;

  DocDelta._() : super();
  factory DocDelta({
    $core.String? docId,
    $core.String? data,
  }) {
    final _result = create();
    if (docId != null) {
      _result.docId = docId;
    }
    if (data != null) {
      _result.data = data;
    }
    return _result;
  }
  factory DocDelta.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory DocDelta.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  DocDelta clone() => DocDelta()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  DocDelta copyWith(void Function(DocDelta) updates) => super.copyWith((message) => updates(message as DocDelta)) as DocDelta; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static DocDelta create() => DocDelta._();
  DocDelta createEmptyInstance() => create();
  static $pb.PbList<DocDelta> createRepeated() => $pb.PbList<DocDelta>();
  @$core.pragma('dart2js:noInline')
  static DocDelta getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<DocDelta>(create);
  static DocDelta? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get docId => $_getSZ(0);
  @$pb.TagNumber(1)
  set docId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasDocId() => $_has(0);
  @$pb.TagNumber(1)
  void clearDocId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get data => $_getSZ(1);
  @$pb.TagNumber(2)
  set data($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasData() => $_has(1);
  @$pb.TagNumber(2)
  void clearData() => clearField(2);
}

class NewDocUser extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'NewDocUser', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'userId')
    ..aInt64(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'revId')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'docId')
    ..hasRequiredFields = false
  ;

  NewDocUser._() : super();
  factory NewDocUser({
    $core.String? userId,
    $fixnum.Int64? revId,
    $core.String? docId,
  }) {
    final _result = create();
    if (userId != null) {
      _result.userId = userId;
    }
    if (revId != null) {
      _result.revId = revId;
    }
    if (docId != null) {
      _result.docId = docId;
    }
    return _result;
  }
  factory NewDocUser.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory NewDocUser.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  NewDocUser clone() => NewDocUser()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  NewDocUser copyWith(void Function(NewDocUser) updates) => super.copyWith((message) => updates(message as NewDocUser)) as NewDocUser; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static NewDocUser create() => NewDocUser._();
  NewDocUser createEmptyInstance() => create();
  static $pb.PbList<NewDocUser> createRepeated() => $pb.PbList<NewDocUser>();
  @$core.pragma('dart2js:noInline')
  static NewDocUser getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<NewDocUser>(create);
  static NewDocUser? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get userId => $_getSZ(0);
  @$pb.TagNumber(1)
  set userId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasUserId() => $_has(0);
  @$pb.TagNumber(1)
  void clearUserId() => clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get revId => $_getI64(1);
  @$pb.TagNumber(2)
  set revId($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasRevId() => $_has(1);
  @$pb.TagNumber(2)
  void clearRevId() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get docId => $_getSZ(2);
  @$pb.TagNumber(3)
  set docId($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasDocId() => $_has(2);
  @$pb.TagNumber(3)
  void clearDocId() => clearField(3);
}

class QueryDocParams extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'QueryDocParams', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'docId')
    ..hasRequiredFields = false
  ;

  QueryDocParams._() : super();
  factory QueryDocParams({
    $core.String? docId,
  }) {
    final _result = create();
    if (docId != null) {
      _result.docId = docId;
    }
    return _result;
  }
  factory QueryDocParams.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory QueryDocParams.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  QueryDocParams clone() => QueryDocParams()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  QueryDocParams copyWith(void Function(QueryDocParams) updates) => super.copyWith((message) => updates(message as QueryDocParams)) as QueryDocParams; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static QueryDocParams create() => QueryDocParams._();
  QueryDocParams createEmptyInstance() => create();
  static $pb.PbList<QueryDocParams> createRepeated() => $pb.PbList<QueryDocParams>();
  @$core.pragma('dart2js:noInline')
  static QueryDocParams getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<QueryDocParams>(create);
  static QueryDocParams? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get docId => $_getSZ(0);
  @$pb.TagNumber(1)
  set docId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasDocId() => $_has(0);
  @$pb.TagNumber(1)
  void clearDocId() => clearField(1);
}

