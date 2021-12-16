///
//  Generated code. Do not modify.
//  source: ws.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'ws.pbenum.dart';

export 'ws.pbenum.dart';

enum DocumentWSData_OneOfId {
  id, 
  notSet
}

class DocumentWSData extends $pb.GeneratedMessage {
  static const $core.Map<$core.int, DocumentWSData_OneOfId> _DocumentWSData_OneOfIdByTag = {
    4 : DocumentWSData_OneOfId.id,
    0 : DocumentWSData_OneOfId.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'DocumentWSData', createEmptyInstance: create)
    ..oo(0, [4])
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'docId')
    ..e<DocumentWSDataType>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'ty', $pb.PbFieldType.OE, defaultOrMaker: DocumentWSDataType.Acked, valueOf: DocumentWSDataType.valueOf, enumValues: DocumentWSDataType.values)
    ..a<$core.List<$core.int>>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'data', $pb.PbFieldType.OY)
    ..aInt64(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'id')
    ..hasRequiredFields = false
  ;

  DocumentWSData._() : super();
  factory DocumentWSData({
    $core.String? docId,
    DocumentWSDataType? ty,
    $core.List<$core.int>? data,
    $fixnum.Int64? id,
  }) {
    final _result = create();
    if (docId != null) {
      _result.docId = docId;
    }
    if (ty != null) {
      _result.ty = ty;
    }
    if (data != null) {
      _result.data = data;
    }
    if (id != null) {
      _result.id = id;
    }
    return _result;
  }
  factory DocumentWSData.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory DocumentWSData.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  DocumentWSData clone() => DocumentWSData()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  DocumentWSData copyWith(void Function(DocumentWSData) updates) => super.copyWith((message) => updates(message as DocumentWSData)) as DocumentWSData; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static DocumentWSData create() => DocumentWSData._();
  DocumentWSData createEmptyInstance() => create();
  static $pb.PbList<DocumentWSData> createRepeated() => $pb.PbList<DocumentWSData>();
  @$core.pragma('dart2js:noInline')
  static DocumentWSData getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<DocumentWSData>(create);
  static DocumentWSData? _defaultInstance;

  DocumentWSData_OneOfId whichOneOfId() => _DocumentWSData_OneOfIdByTag[$_whichOneof(0)]!;
  void clearOneOfId() => clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $core.String get docId => $_getSZ(0);
  @$pb.TagNumber(1)
  set docId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasDocId() => $_has(0);
  @$pb.TagNumber(1)
  void clearDocId() => clearField(1);

  @$pb.TagNumber(2)
  DocumentWSDataType get ty => $_getN(1);
  @$pb.TagNumber(2)
  set ty(DocumentWSDataType v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasTy() => $_has(1);
  @$pb.TagNumber(2)
  void clearTy() => clearField(2);

  @$pb.TagNumber(3)
  $core.List<$core.int> get data => $_getN(2);
  @$pb.TagNumber(3)
  set data($core.List<$core.int> v) { $_setBytes(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasData() => $_has(2);
  @$pb.TagNumber(3)
  void clearData() => clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get id => $_getI64(3);
  @$pb.TagNumber(4)
  set id($fixnum.Int64 v) { $_setInt64(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasId() => $_has(3);
  @$pb.TagNumber(4)
  void clearId() => clearField(4);
}

class DocumentConnected extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'DocumentConnected', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'userId')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'docId')
    ..aInt64(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'revId')
    ..hasRequiredFields = false
  ;

  DocumentConnected._() : super();
  factory DocumentConnected({
    $core.String? userId,
    $core.String? docId,
    $fixnum.Int64? revId,
  }) {
    final _result = create();
    if (userId != null) {
      _result.userId = userId;
    }
    if (docId != null) {
      _result.docId = docId;
    }
    if (revId != null) {
      _result.revId = revId;
    }
    return _result;
  }
  factory DocumentConnected.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory DocumentConnected.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  DocumentConnected clone() => DocumentConnected()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  DocumentConnected copyWith(void Function(DocumentConnected) updates) => super.copyWith((message) => updates(message as DocumentConnected)) as DocumentConnected; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static DocumentConnected create() => DocumentConnected._();
  DocumentConnected createEmptyInstance() => create();
  static $pb.PbList<DocumentConnected> createRepeated() => $pb.PbList<DocumentConnected>();
  @$core.pragma('dart2js:noInline')
  static DocumentConnected getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<DocumentConnected>(create);
  static DocumentConnected? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get userId => $_getSZ(0);
  @$pb.TagNumber(1)
  set userId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasUserId() => $_has(0);
  @$pb.TagNumber(1)
  void clearUserId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get docId => $_getSZ(1);
  @$pb.TagNumber(2)
  set docId($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasDocId() => $_has(1);
  @$pb.TagNumber(2)
  void clearDocId() => clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get revId => $_getI64(2);
  @$pb.TagNumber(3)
  set revId($fixnum.Int64 v) { $_setInt64(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasRevId() => $_has(2);
  @$pb.TagNumber(3)
  void clearRevId() => clearField(3);
}

