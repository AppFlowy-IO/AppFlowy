///
//  Generated code. Do not modify.
//  source: select_type_option.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'cell_entities.pb.dart' as $0;

import 'select_type_option.pbenum.dart';

export 'select_type_option.pbenum.dart';

class SelectOptionPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'SelectOptionPB', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'id')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'name')
    ..e<SelectOptionColorPB>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'color', $pb.PbFieldType.OE, defaultOrMaker: SelectOptionColorPB.Purple, valueOf: SelectOptionColorPB.valueOf, enumValues: SelectOptionColorPB.values)
    ..hasRequiredFields = false
  ;

  SelectOptionPB._() : super();
  factory SelectOptionPB({
    $core.String? id,
    $core.String? name,
    SelectOptionColorPB? color,
  }) {
    final _result = create();
    if (id != null) {
      _result.id = id;
    }
    if (name != null) {
      _result.name = name;
    }
    if (color != null) {
      _result.color = color;
    }
    return _result;
  }
  factory SelectOptionPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory SelectOptionPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  SelectOptionPB clone() => SelectOptionPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  SelectOptionPB copyWith(void Function(SelectOptionPB) updates) => super.copyWith((message) => updates(message as SelectOptionPB)) as SelectOptionPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static SelectOptionPB create() => SelectOptionPB._();
  SelectOptionPB createEmptyInstance() => create();
  static $pb.PbList<SelectOptionPB> createRepeated() => $pb.PbList<SelectOptionPB>();
  @$core.pragma('dart2js:noInline')
  static SelectOptionPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SelectOptionPB>(create);
  static SelectOptionPB? _defaultInstance;

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
  SelectOptionColorPB get color => $_getN(2);
  @$pb.TagNumber(3)
  set color(SelectOptionColorPB v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasColor() => $_has(2);
  @$pb.TagNumber(3)
  void clearColor() => clearField(3);
}

class SelectOptionCellChangesetPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'SelectOptionCellChangesetPB', createEmptyInstance: create)
    ..aOM<$0.CellPathPB>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'cellIdentifier', subBuilder: $0.CellPathPB.create)
    ..pPS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'insertOptionIds')
    ..pPS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'deleteOptionIds')
    ..hasRequiredFields = false
  ;

  SelectOptionCellChangesetPB._() : super();
  factory SelectOptionCellChangesetPB({
    $0.CellPathPB? cellIdentifier,
    $core.Iterable<$core.String>? insertOptionIds,
    $core.Iterable<$core.String>? deleteOptionIds,
  }) {
    final _result = create();
    if (cellIdentifier != null) {
      _result.cellIdentifier = cellIdentifier;
    }
    if (insertOptionIds != null) {
      _result.insertOptionIds.addAll(insertOptionIds);
    }
    if (deleteOptionIds != null) {
      _result.deleteOptionIds.addAll(deleteOptionIds);
    }
    return _result;
  }
  factory SelectOptionCellChangesetPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory SelectOptionCellChangesetPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  SelectOptionCellChangesetPB clone() => SelectOptionCellChangesetPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  SelectOptionCellChangesetPB copyWith(void Function(SelectOptionCellChangesetPB) updates) => super.copyWith((message) => updates(message as SelectOptionCellChangesetPB)) as SelectOptionCellChangesetPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static SelectOptionCellChangesetPB create() => SelectOptionCellChangesetPB._();
  SelectOptionCellChangesetPB createEmptyInstance() => create();
  static $pb.PbList<SelectOptionCellChangesetPB> createRepeated() => $pb.PbList<SelectOptionCellChangesetPB>();
  @$core.pragma('dart2js:noInline')
  static SelectOptionCellChangesetPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SelectOptionCellChangesetPB>(create);
  static SelectOptionCellChangesetPB? _defaultInstance;

  @$pb.TagNumber(1)
  $0.CellPathPB get cellIdentifier => $_getN(0);
  @$pb.TagNumber(1)
  set cellIdentifier($0.CellPathPB v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasCellIdentifier() => $_has(0);
  @$pb.TagNumber(1)
  void clearCellIdentifier() => clearField(1);
  @$pb.TagNumber(1)
  $0.CellPathPB ensureCellIdentifier() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.List<$core.String> get insertOptionIds => $_getList(1);

  @$pb.TagNumber(3)
  $core.List<$core.String> get deleteOptionIds => $_getList(2);
}

class SelectOptionCellDataPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'SelectOptionCellDataPB', createEmptyInstance: create)
    ..pc<SelectOptionPB>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'options', $pb.PbFieldType.PM, subBuilder: SelectOptionPB.create)
    ..pc<SelectOptionPB>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'selectOptions', $pb.PbFieldType.PM, subBuilder: SelectOptionPB.create)
    ..hasRequiredFields = false
  ;

  SelectOptionCellDataPB._() : super();
  factory SelectOptionCellDataPB({
    $core.Iterable<SelectOptionPB>? options,
    $core.Iterable<SelectOptionPB>? selectOptions,
  }) {
    final _result = create();
    if (options != null) {
      _result.options.addAll(options);
    }
    if (selectOptions != null) {
      _result.selectOptions.addAll(selectOptions);
    }
    return _result;
  }
  factory SelectOptionCellDataPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory SelectOptionCellDataPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  SelectOptionCellDataPB clone() => SelectOptionCellDataPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  SelectOptionCellDataPB copyWith(void Function(SelectOptionCellDataPB) updates) => super.copyWith((message) => updates(message as SelectOptionCellDataPB)) as SelectOptionCellDataPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static SelectOptionCellDataPB create() => SelectOptionCellDataPB._();
  SelectOptionCellDataPB createEmptyInstance() => create();
  static $pb.PbList<SelectOptionCellDataPB> createRepeated() => $pb.PbList<SelectOptionCellDataPB>();
  @$core.pragma('dart2js:noInline')
  static SelectOptionCellDataPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SelectOptionCellDataPB>(create);
  static SelectOptionCellDataPB? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<SelectOptionPB> get options => $_getList(0);

  @$pb.TagNumber(2)
  $core.List<SelectOptionPB> get selectOptions => $_getList(1);
}

class SelectOptionChangesetPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'SelectOptionChangesetPB', createEmptyInstance: create)
    ..aOM<$0.CellPathPB>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'cellIdentifier', subBuilder: $0.CellPathPB.create)
    ..pc<SelectOptionPB>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'insertOptions', $pb.PbFieldType.PM, subBuilder: SelectOptionPB.create)
    ..pc<SelectOptionPB>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'updateOptions', $pb.PbFieldType.PM, subBuilder: SelectOptionPB.create)
    ..pc<SelectOptionPB>(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'deleteOptions', $pb.PbFieldType.PM, subBuilder: SelectOptionPB.create)
    ..hasRequiredFields = false
  ;

  SelectOptionChangesetPB._() : super();
  factory SelectOptionChangesetPB({
    $0.CellPathPB? cellIdentifier,
    $core.Iterable<SelectOptionPB>? insertOptions,
    $core.Iterable<SelectOptionPB>? updateOptions,
    $core.Iterable<SelectOptionPB>? deleteOptions,
  }) {
    final _result = create();
    if (cellIdentifier != null) {
      _result.cellIdentifier = cellIdentifier;
    }
    if (insertOptions != null) {
      _result.insertOptions.addAll(insertOptions);
    }
    if (updateOptions != null) {
      _result.updateOptions.addAll(updateOptions);
    }
    if (deleteOptions != null) {
      _result.deleteOptions.addAll(deleteOptions);
    }
    return _result;
  }
  factory SelectOptionChangesetPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory SelectOptionChangesetPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  SelectOptionChangesetPB clone() => SelectOptionChangesetPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  SelectOptionChangesetPB copyWith(void Function(SelectOptionChangesetPB) updates) => super.copyWith((message) => updates(message as SelectOptionChangesetPB)) as SelectOptionChangesetPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static SelectOptionChangesetPB create() => SelectOptionChangesetPB._();
  SelectOptionChangesetPB createEmptyInstance() => create();
  static $pb.PbList<SelectOptionChangesetPB> createRepeated() => $pb.PbList<SelectOptionChangesetPB>();
  @$core.pragma('dart2js:noInline')
  static SelectOptionChangesetPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SelectOptionChangesetPB>(create);
  static SelectOptionChangesetPB? _defaultInstance;

  @$pb.TagNumber(1)
  $0.CellPathPB get cellIdentifier => $_getN(0);
  @$pb.TagNumber(1)
  set cellIdentifier($0.CellPathPB v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasCellIdentifier() => $_has(0);
  @$pb.TagNumber(1)
  void clearCellIdentifier() => clearField(1);
  @$pb.TagNumber(1)
  $0.CellPathPB ensureCellIdentifier() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.List<SelectOptionPB> get insertOptions => $_getList(1);

  @$pb.TagNumber(3)
  $core.List<SelectOptionPB> get updateOptions => $_getList(2);

  @$pb.TagNumber(4)
  $core.List<SelectOptionPB> get deleteOptions => $_getList(3);
}

