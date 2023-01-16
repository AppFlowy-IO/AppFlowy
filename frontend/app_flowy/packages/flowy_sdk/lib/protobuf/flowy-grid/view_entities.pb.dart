///
//  Generated code. Do not modify.
//  source: view_entities.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'row_entities.pb.dart' as $0;

class GridRowsVisibilityChangesetPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'GridRowsVisibilityChangesetPB', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'viewId')
    ..pc<$0.InsertedRowPB>(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'visibleRows', $pb.PbFieldType.PM, subBuilder: $0.InsertedRowPB.create)
    ..pPS(6, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'invisibleRows')
    ..hasRequiredFields = false
  ;

  GridRowsVisibilityChangesetPB._() : super();
  factory GridRowsVisibilityChangesetPB({
    $core.String? viewId,
    $core.Iterable<$0.InsertedRowPB>? visibleRows,
    $core.Iterable<$core.String>? invisibleRows,
  }) {
    final _result = create();
    if (viewId != null) {
      _result.viewId = viewId;
    }
    if (visibleRows != null) {
      _result.visibleRows.addAll(visibleRows);
    }
    if (invisibleRows != null) {
      _result.invisibleRows.addAll(invisibleRows);
    }
    return _result;
  }
  factory GridRowsVisibilityChangesetPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GridRowsVisibilityChangesetPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GridRowsVisibilityChangesetPB clone() => GridRowsVisibilityChangesetPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GridRowsVisibilityChangesetPB copyWith(void Function(GridRowsVisibilityChangesetPB) updates) => super.copyWith((message) => updates(message as GridRowsVisibilityChangesetPB)) as GridRowsVisibilityChangesetPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static GridRowsVisibilityChangesetPB create() => GridRowsVisibilityChangesetPB._();
  GridRowsVisibilityChangesetPB createEmptyInstance() => create();
  static $pb.PbList<GridRowsVisibilityChangesetPB> createRepeated() => $pb.PbList<GridRowsVisibilityChangesetPB>();
  @$core.pragma('dart2js:noInline')
  static GridRowsVisibilityChangesetPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GridRowsVisibilityChangesetPB>(create);
  static GridRowsVisibilityChangesetPB? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get viewId => $_getSZ(0);
  @$pb.TagNumber(1)
  set viewId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasViewId() => $_has(0);
  @$pb.TagNumber(1)
  void clearViewId() => clearField(1);

  @$pb.TagNumber(5)
  $core.List<$0.InsertedRowPB> get visibleRows => $_getList(1);

  @$pb.TagNumber(6)
  $core.List<$core.String> get invisibleRows => $_getList(2);
}

class GridViewRowsChangesetPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'GridViewRowsChangesetPB', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'viewId')
    ..pc<$0.InsertedRowPB>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'insertedRows', $pb.PbFieldType.PM, subBuilder: $0.InsertedRowPB.create)
    ..pPS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'deletedRows')
    ..pc<$0.UpdatedRowPB>(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'updatedRows', $pb.PbFieldType.PM, subBuilder: $0.UpdatedRowPB.create)
    ..hasRequiredFields = false
  ;

  GridViewRowsChangesetPB._() : super();
  factory GridViewRowsChangesetPB({
    $core.String? viewId,
    $core.Iterable<$0.InsertedRowPB>? insertedRows,
    $core.Iterable<$core.String>? deletedRows,
    $core.Iterable<$0.UpdatedRowPB>? updatedRows,
  }) {
    final _result = create();
    if (viewId != null) {
      _result.viewId = viewId;
    }
    if (insertedRows != null) {
      _result.insertedRows.addAll(insertedRows);
    }
    if (deletedRows != null) {
      _result.deletedRows.addAll(deletedRows);
    }
    if (updatedRows != null) {
      _result.updatedRows.addAll(updatedRows);
    }
    return _result;
  }
  factory GridViewRowsChangesetPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GridViewRowsChangesetPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GridViewRowsChangesetPB clone() => GridViewRowsChangesetPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GridViewRowsChangesetPB copyWith(void Function(GridViewRowsChangesetPB) updates) => super.copyWith((message) => updates(message as GridViewRowsChangesetPB)) as GridViewRowsChangesetPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static GridViewRowsChangesetPB create() => GridViewRowsChangesetPB._();
  GridViewRowsChangesetPB createEmptyInstance() => create();
  static $pb.PbList<GridViewRowsChangesetPB> createRepeated() => $pb.PbList<GridViewRowsChangesetPB>();
  @$core.pragma('dart2js:noInline')
  static GridViewRowsChangesetPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GridViewRowsChangesetPB>(create);
  static GridViewRowsChangesetPB? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get viewId => $_getSZ(0);
  @$pb.TagNumber(1)
  set viewId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasViewId() => $_has(0);
  @$pb.TagNumber(1)
  void clearViewId() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<$0.InsertedRowPB> get insertedRows => $_getList(1);

  @$pb.TagNumber(3)
  $core.List<$core.String> get deletedRows => $_getList(2);

  @$pb.TagNumber(4)
  $core.List<$0.UpdatedRowPB> get updatedRows => $_getList(3);
}

