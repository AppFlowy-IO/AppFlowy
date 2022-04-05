///
//  Generated code. Do not modify.
//  source: selection_type_option.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'selection_type_option.pbenum.dart';

export 'selection_type_option.pbenum.dart';

class SingleSelectTypeOption extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'SingleSelectTypeOption', createEmptyInstance: create)
    ..pc<SelectOption>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'options', $pb.PbFieldType.PM, subBuilder: SelectOption.create)
    ..aOB(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'disableColor')
    ..hasRequiredFields = false
  ;

  SingleSelectTypeOption._() : super();
  factory SingleSelectTypeOption({
    $core.Iterable<SelectOption>? options,
    $core.bool? disableColor,
  }) {
    final _result = create();
    if (options != null) {
      _result.options.addAll(options);
    }
    if (disableColor != null) {
      _result.disableColor = disableColor;
    }
    return _result;
  }
  factory SingleSelectTypeOption.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory SingleSelectTypeOption.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  SingleSelectTypeOption clone() => SingleSelectTypeOption()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  SingleSelectTypeOption copyWith(void Function(SingleSelectTypeOption) updates) => super.copyWith((message) => updates(message as SingleSelectTypeOption)) as SingleSelectTypeOption; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static SingleSelectTypeOption create() => SingleSelectTypeOption._();
  SingleSelectTypeOption createEmptyInstance() => create();
  static $pb.PbList<SingleSelectTypeOption> createRepeated() => $pb.PbList<SingleSelectTypeOption>();
  @$core.pragma('dart2js:noInline')
  static SingleSelectTypeOption getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SingleSelectTypeOption>(create);
  static SingleSelectTypeOption? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<SelectOption> get options => $_getList(0);

  @$pb.TagNumber(2)
  $core.bool get disableColor => $_getBF(1);
  @$pb.TagNumber(2)
  set disableColor($core.bool v) { $_setBool(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasDisableColor() => $_has(1);
  @$pb.TagNumber(2)
  void clearDisableColor() => clearField(2);
}

class MultiSelectTypeOption extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'MultiSelectTypeOption', createEmptyInstance: create)
    ..pc<SelectOption>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'options', $pb.PbFieldType.PM, subBuilder: SelectOption.create)
    ..aOB(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'disableColor')
    ..hasRequiredFields = false
  ;

  MultiSelectTypeOption._() : super();
  factory MultiSelectTypeOption({
    $core.Iterable<SelectOption>? options,
    $core.bool? disableColor,
  }) {
    final _result = create();
    if (options != null) {
      _result.options.addAll(options);
    }
    if (disableColor != null) {
      _result.disableColor = disableColor;
    }
    return _result;
  }
  factory MultiSelectTypeOption.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory MultiSelectTypeOption.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  MultiSelectTypeOption clone() => MultiSelectTypeOption()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  MultiSelectTypeOption copyWith(void Function(MultiSelectTypeOption) updates) => super.copyWith((message) => updates(message as MultiSelectTypeOption)) as MultiSelectTypeOption; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static MultiSelectTypeOption create() => MultiSelectTypeOption._();
  MultiSelectTypeOption createEmptyInstance() => create();
  static $pb.PbList<MultiSelectTypeOption> createRepeated() => $pb.PbList<MultiSelectTypeOption>();
  @$core.pragma('dart2js:noInline')
  static MultiSelectTypeOption getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<MultiSelectTypeOption>(create);
  static MultiSelectTypeOption? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<SelectOption> get options => $_getList(0);

  @$pb.TagNumber(2)
  $core.bool get disableColor => $_getBF(1);
  @$pb.TagNumber(2)
  set disableColor($core.bool v) { $_setBool(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasDisableColor() => $_has(1);
  @$pb.TagNumber(2)
  void clearDisableColor() => clearField(2);
}

class SelectOption extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'SelectOption', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'id')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'name')
    ..e<SelectOptionColor>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'color', $pb.PbFieldType.OE, defaultOrMaker: SelectOptionColor.Purple, valueOf: SelectOptionColor.valueOf, enumValues: SelectOptionColor.values)
    ..hasRequiredFields = false
  ;

  SelectOption._() : super();
  factory SelectOption({
    $core.String? id,
    $core.String? name,
    SelectOptionColor? color,
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
  factory SelectOption.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory SelectOption.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  SelectOption clone() => SelectOption()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  SelectOption copyWith(void Function(SelectOption) updates) => super.copyWith((message) => updates(message as SelectOption)) as SelectOption; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static SelectOption create() => SelectOption._();
  SelectOption createEmptyInstance() => create();
  static $pb.PbList<SelectOption> createRepeated() => $pb.PbList<SelectOption>();
  @$core.pragma('dart2js:noInline')
  static SelectOption getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SelectOption>(create);
  static SelectOption? _defaultInstance;

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
  SelectOptionColor get color => $_getN(2);
  @$pb.TagNumber(3)
  set color(SelectOptionColor v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasColor() => $_has(2);
  @$pb.TagNumber(3)
  void clearColor() => clearField(3);
}

enum SelectOptionChangesetPayload_OneOfInsertOptionId {
  insertOptionId, 
  notSet
}

enum SelectOptionChangesetPayload_OneOfDeleteOptionId {
  deleteOptionId, 
  notSet
}

class SelectOptionChangesetPayload extends $pb.GeneratedMessage {
  static const $core.Map<$core.int, SelectOptionChangesetPayload_OneOfInsertOptionId> _SelectOptionChangesetPayload_OneOfInsertOptionIdByTag = {
    3 : SelectOptionChangesetPayload_OneOfInsertOptionId.insertOptionId,
    0 : SelectOptionChangesetPayload_OneOfInsertOptionId.notSet
  };
  static const $core.Map<$core.int, SelectOptionChangesetPayload_OneOfDeleteOptionId> _SelectOptionChangesetPayload_OneOfDeleteOptionIdByTag = {
    4 : SelectOptionChangesetPayload_OneOfDeleteOptionId.deleteOptionId,
    0 : SelectOptionChangesetPayload_OneOfDeleteOptionId.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'SelectOptionChangesetPayload', createEmptyInstance: create)
    ..oo(0, [3])
    ..oo(1, [4])
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'gridId')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'rowId')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'insertOptionId')
    ..aOS(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'deleteOptionId')
    ..hasRequiredFields = false
  ;

  SelectOptionChangesetPayload._() : super();
  factory SelectOptionChangesetPayload({
    $core.String? gridId,
    $core.String? rowId,
    $core.String? insertOptionId,
    $core.String? deleteOptionId,
  }) {
    final _result = create();
    if (gridId != null) {
      _result.gridId = gridId;
    }
    if (rowId != null) {
      _result.rowId = rowId;
    }
    if (insertOptionId != null) {
      _result.insertOptionId = insertOptionId;
    }
    if (deleteOptionId != null) {
      _result.deleteOptionId = deleteOptionId;
    }
    return _result;
  }
  factory SelectOptionChangesetPayload.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory SelectOptionChangesetPayload.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  SelectOptionChangesetPayload clone() => SelectOptionChangesetPayload()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  SelectOptionChangesetPayload copyWith(void Function(SelectOptionChangesetPayload) updates) => super.copyWith((message) => updates(message as SelectOptionChangesetPayload)) as SelectOptionChangesetPayload; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static SelectOptionChangesetPayload create() => SelectOptionChangesetPayload._();
  SelectOptionChangesetPayload createEmptyInstance() => create();
  static $pb.PbList<SelectOptionChangesetPayload> createRepeated() => $pb.PbList<SelectOptionChangesetPayload>();
  @$core.pragma('dart2js:noInline')
  static SelectOptionChangesetPayload getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SelectOptionChangesetPayload>(create);
  static SelectOptionChangesetPayload? _defaultInstance;

  SelectOptionChangesetPayload_OneOfInsertOptionId whichOneOfInsertOptionId() => _SelectOptionChangesetPayload_OneOfInsertOptionIdByTag[$_whichOneof(0)]!;
  void clearOneOfInsertOptionId() => clearField($_whichOneof(0));

  SelectOptionChangesetPayload_OneOfDeleteOptionId whichOneOfDeleteOptionId() => _SelectOptionChangesetPayload_OneOfDeleteOptionIdByTag[$_whichOneof(1)]!;
  void clearOneOfDeleteOptionId() => clearField($_whichOneof(1));

  @$pb.TagNumber(1)
  $core.String get gridId => $_getSZ(0);
  @$pb.TagNumber(1)
  set gridId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasGridId() => $_has(0);
  @$pb.TagNumber(1)
  void clearGridId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get rowId => $_getSZ(1);
  @$pb.TagNumber(2)
  set rowId($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasRowId() => $_has(1);
  @$pb.TagNumber(2)
  void clearRowId() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get insertOptionId => $_getSZ(2);
  @$pb.TagNumber(3)
  set insertOptionId($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasInsertOptionId() => $_has(2);
  @$pb.TagNumber(3)
  void clearInsertOptionId() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get deleteOptionId => $_getSZ(3);
  @$pb.TagNumber(4)
  set deleteOptionId($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasDeleteOptionId() => $_has(3);
  @$pb.TagNumber(4)
  void clearDeleteOptionId() => clearField(4);
}

class SelectOptionContext extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'SelectOptionContext', createEmptyInstance: create)
    ..pc<SelectOption>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'options', $pb.PbFieldType.PM, subBuilder: SelectOption.create)
    ..pc<SelectOption>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'selectOptions', $pb.PbFieldType.PM, subBuilder: SelectOption.create)
    ..hasRequiredFields = false
  ;

  SelectOptionContext._() : super();
  factory SelectOptionContext({
    $core.Iterable<SelectOption>? options,
    $core.Iterable<SelectOption>? selectOptions,
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
  factory SelectOptionContext.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory SelectOptionContext.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  SelectOptionContext clone() => SelectOptionContext()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  SelectOptionContext copyWith(void Function(SelectOptionContext) updates) => super.copyWith((message) => updates(message as SelectOptionContext)) as SelectOptionContext; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static SelectOptionContext create() => SelectOptionContext._();
  SelectOptionContext createEmptyInstance() => create();
  static $pb.PbList<SelectOptionContext> createRepeated() => $pb.PbList<SelectOptionContext>();
  @$core.pragma('dart2js:noInline')
  static SelectOptionContext getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SelectOptionContext>(create);
  static SelectOptionContext? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<SelectOption> get options => $_getList(0);

  @$pb.TagNumber(2)
  $core.List<SelectOption> get selectOptions => $_getList(1);
}

