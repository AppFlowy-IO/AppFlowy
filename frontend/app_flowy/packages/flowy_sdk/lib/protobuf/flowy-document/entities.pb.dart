///
//  Generated code. Do not modify.
//  source: entities.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'entities.pbenum.dart';

export 'entities.pbenum.dart';

class EditPayloadPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'EditPayloadPB', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'docId')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'operations')
    ..hasRequiredFields = false
  ;

  EditPayloadPB._() : super();
  factory EditPayloadPB({
    $core.String? docId,
    $core.String? operations,
  }) {
    final _result = create();
    if (docId != null) {
      _result.docId = docId;
    }
    if (operations != null) {
      _result.operations = operations;
    }
    return _result;
  }
  factory EditPayloadPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory EditPayloadPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  EditPayloadPB clone() => EditPayloadPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  EditPayloadPB copyWith(void Function(EditPayloadPB) updates) => super.copyWith((message) => updates(message as EditPayloadPB)) as EditPayloadPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static EditPayloadPB create() => EditPayloadPB._();
  EditPayloadPB createEmptyInstance() => create();
  static $pb.PbList<EditPayloadPB> createRepeated() => $pb.PbList<EditPayloadPB>();
  @$core.pragma('dart2js:noInline')
  static EditPayloadPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<EditPayloadPB>(create);
  static EditPayloadPB? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get docId => $_getSZ(0);
  @$pb.TagNumber(1)
  set docId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasDocId() => $_has(0);
  @$pb.TagNumber(1)
  void clearDocId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get operations => $_getSZ(1);
  @$pb.TagNumber(2)
  set operations($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasOperations() => $_has(1);
  @$pb.TagNumber(2)
  void clearOperations() => clearField(2);
}

class DocumentSnapshotPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'DocumentSnapshotPB', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'docId')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'snapshot')
    ..hasRequiredFields = false
  ;

  DocumentSnapshotPB._() : super();
  factory DocumentSnapshotPB({
    $core.String? docId,
    $core.String? snapshot,
  }) {
    final _result = create();
    if (docId != null) {
      _result.docId = docId;
    }
    if (snapshot != null) {
      _result.snapshot = snapshot;
    }
    return _result;
  }
  factory DocumentSnapshotPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory DocumentSnapshotPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  DocumentSnapshotPB clone() => DocumentSnapshotPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  DocumentSnapshotPB copyWith(void Function(DocumentSnapshotPB) updates) => super.copyWith((message) => updates(message as DocumentSnapshotPB)) as DocumentSnapshotPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static DocumentSnapshotPB create() => DocumentSnapshotPB._();
  DocumentSnapshotPB createEmptyInstance() => create();
  static $pb.PbList<DocumentSnapshotPB> createRepeated() => $pb.PbList<DocumentSnapshotPB>();
  @$core.pragma('dart2js:noInline')
  static DocumentSnapshotPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<DocumentSnapshotPB>(create);
  static DocumentSnapshotPB? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get docId => $_getSZ(0);
  @$pb.TagNumber(1)
  set docId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasDocId() => $_has(0);
  @$pb.TagNumber(1)
  void clearDocId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get snapshot => $_getSZ(1);
  @$pb.TagNumber(2)
  set snapshot($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasSnapshot() => $_has(1);
  @$pb.TagNumber(2)
  void clearSnapshot() => clearField(2);
}

class ExportPayloadPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'ExportPayloadPB', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'viewId')
    ..e<ExportType>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'exportType', $pb.PbFieldType.OE, defaultOrMaker: ExportType.Text, valueOf: ExportType.valueOf, enumValues: ExportType.values)
    ..e<DocumentVersionPB>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'documentVersion', $pb.PbFieldType.OE, defaultOrMaker: DocumentVersionPB.V0, valueOf: DocumentVersionPB.valueOf, enumValues: DocumentVersionPB.values)
    ..hasRequiredFields = false
  ;

  ExportPayloadPB._() : super();
  factory ExportPayloadPB({
    $core.String? viewId,
    ExportType? exportType,
    DocumentVersionPB? documentVersion,
  }) {
    final _result = create();
    if (viewId != null) {
      _result.viewId = viewId;
    }
    if (exportType != null) {
      _result.exportType = exportType;
    }
    if (documentVersion != null) {
      _result.documentVersion = documentVersion;
    }
    return _result;
  }
  factory ExportPayloadPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ExportPayloadPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ExportPayloadPB clone() => ExportPayloadPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ExportPayloadPB copyWith(void Function(ExportPayloadPB) updates) => super.copyWith((message) => updates(message as ExportPayloadPB)) as ExportPayloadPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static ExportPayloadPB create() => ExportPayloadPB._();
  ExportPayloadPB createEmptyInstance() => create();
  static $pb.PbList<ExportPayloadPB> createRepeated() => $pb.PbList<ExportPayloadPB>();
  @$core.pragma('dart2js:noInline')
  static ExportPayloadPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ExportPayloadPB>(create);
  static ExportPayloadPB? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get viewId => $_getSZ(0);
  @$pb.TagNumber(1)
  set viewId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasViewId() => $_has(0);
  @$pb.TagNumber(1)
  void clearViewId() => clearField(1);

  @$pb.TagNumber(2)
  ExportType get exportType => $_getN(1);
  @$pb.TagNumber(2)
  set exportType(ExportType v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasExportType() => $_has(1);
  @$pb.TagNumber(2)
  void clearExportType() => clearField(2);

  @$pb.TagNumber(3)
  DocumentVersionPB get documentVersion => $_getN(2);
  @$pb.TagNumber(3)
  set documentVersion(DocumentVersionPB v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasDocumentVersion() => $_has(2);
  @$pb.TagNumber(3)
  void clearDocumentVersion() => clearField(3);
}

class OpenDocumentContextPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'OpenDocumentContextPB', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'documentId')
    ..e<DocumentVersionPB>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'documentVersion', $pb.PbFieldType.OE, defaultOrMaker: DocumentVersionPB.V0, valueOf: DocumentVersionPB.valueOf, enumValues: DocumentVersionPB.values)
    ..hasRequiredFields = false
  ;

  OpenDocumentContextPB._() : super();
  factory OpenDocumentContextPB({
    $core.String? documentId,
    DocumentVersionPB? documentVersion,
  }) {
    final _result = create();
    if (documentId != null) {
      _result.documentId = documentId;
    }
    if (documentVersion != null) {
      _result.documentVersion = documentVersion;
    }
    return _result;
  }
  factory OpenDocumentContextPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory OpenDocumentContextPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  OpenDocumentContextPB clone() => OpenDocumentContextPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  OpenDocumentContextPB copyWith(void Function(OpenDocumentContextPB) updates) => super.copyWith((message) => updates(message as OpenDocumentContextPB)) as OpenDocumentContextPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static OpenDocumentContextPB create() => OpenDocumentContextPB._();
  OpenDocumentContextPB createEmptyInstance() => create();
  static $pb.PbList<OpenDocumentContextPB> createRepeated() => $pb.PbList<OpenDocumentContextPB>();
  @$core.pragma('dart2js:noInline')
  static OpenDocumentContextPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<OpenDocumentContextPB>(create);
  static OpenDocumentContextPB? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get documentId => $_getSZ(0);
  @$pb.TagNumber(1)
  set documentId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasDocumentId() => $_has(0);
  @$pb.TagNumber(1)
  void clearDocumentId() => clearField(1);

  @$pb.TagNumber(2)
  DocumentVersionPB get documentVersion => $_getN(1);
  @$pb.TagNumber(2)
  set documentVersion(DocumentVersionPB v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasDocumentVersion() => $_has(1);
  @$pb.TagNumber(2)
  void clearDocumentVersion() => clearField(2);
}

class ExportDataPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'ExportDataPB', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'data')
    ..e<ExportType>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'exportType', $pb.PbFieldType.OE, defaultOrMaker: ExportType.Text, valueOf: ExportType.valueOf, enumValues: ExportType.values)
    ..hasRequiredFields = false
  ;

  ExportDataPB._() : super();
  factory ExportDataPB({
    $core.String? data,
    ExportType? exportType,
  }) {
    final _result = create();
    if (data != null) {
      _result.data = data;
    }
    if (exportType != null) {
      _result.exportType = exportType;
    }
    return _result;
  }
  factory ExportDataPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ExportDataPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ExportDataPB clone() => ExportDataPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ExportDataPB copyWith(void Function(ExportDataPB) updates) => super.copyWith((message) => updates(message as ExportDataPB)) as ExportDataPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static ExportDataPB create() => ExportDataPB._();
  ExportDataPB createEmptyInstance() => create();
  static $pb.PbList<ExportDataPB> createRepeated() => $pb.PbList<ExportDataPB>();
  @$core.pragma('dart2js:noInline')
  static ExportDataPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ExportDataPB>(create);
  static ExportDataPB? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get data => $_getSZ(0);
  @$pb.TagNumber(1)
  set data($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasData() => $_has(0);
  @$pb.TagNumber(1)
  void clearData() => clearField(1);

  @$pb.TagNumber(2)
  ExportType get exportType => $_getN(1);
  @$pb.TagNumber(2)
  set exportType(ExportType v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasExportType() => $_has(1);
  @$pb.TagNumber(2)
  void clearExportType() => clearField(2);
}

