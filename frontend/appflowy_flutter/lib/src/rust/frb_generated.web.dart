// This file is automatically generated, so please do not edit it.
// @generated by `flutter_rust_bridge`@ 2.9.0.

// ignore_for_file: unused_import, unused_element, unnecessary_import, duplicate_ignore, invalid_use_of_internal_member, annotate_overrides, non_constant_identifier_names, curly_braces_in_flow_control_structures, prefer_const_literals_to_create_immutables, unused_field

// Static analysis wrongly picks the IO variant, thus ignore this
// ignore_for_file: argument_type_not_assignable

import 'dart:async';
import 'dart:convert';
import 'folder/folder.dart';
import 'frb_generated.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated_web.dart';

abstract class RustLibApiImplPlatform extends BaseApiImpl<RustLibWire> {
  RustLibApiImplPlatform({
    required super.handler,
    required super.wire,
    required super.generalizedFrbRustBinding,
    required super.portManager,
  });

  @protected
  AnyhowException dco_decode_AnyhowException(dynamic raw);

  @protected
  String dco_decode_String(dynamic raw);

  @protected
  bool dco_decode_bool(dynamic raw);

  @protected
  bool dco_decode_box_autoadd_bool(dynamic raw);

  @protected
  FolderExtra dco_decode_box_autoadd_folder_extra(dynamic raw);

  @protected
  FolderManager dco_decode_box_autoadd_folder_manager(dynamic raw);

  @protected
  FolderExtra dco_decode_folder_extra(dynamic raw);

  @protected
  FolderItem dco_decode_folder_item(dynamic raw);

  @protected
  FolderManager dco_decode_folder_manager(dynamic raw);

  @protected
  FolderResponse dco_decode_folder_response(dynamic raw);

  @protected
  int dco_decode_i_32(dynamic raw);

  @protected
  PlatformInt64 dco_decode_i_64(dynamic raw);

  @protected
  List<FolderItem> dco_decode_list_folder_item(dynamic raw);

  @protected
  Uint8List dco_decode_list_prim_u_8_strict(dynamic raw);

  @protected
  String? dco_decode_opt_String(dynamic raw);

  @protected
  bool? dco_decode_opt_box_autoadd_bool(dynamic raw);

  @protected
  FolderExtra? dco_decode_opt_box_autoadd_folder_extra(dynamic raw);

  @protected
  RootFolder dco_decode_root_folder(dynamic raw);

  @protected
  int dco_decode_u_8(dynamic raw);

  @protected
  void dco_decode_unit(dynamic raw);

  @protected
  AnyhowException sse_decode_AnyhowException(SseDeserializer deserializer);

  @protected
  String sse_decode_String(SseDeserializer deserializer);

  @protected
  bool sse_decode_bool(SseDeserializer deserializer);

  @protected
  bool sse_decode_box_autoadd_bool(SseDeserializer deserializer);

  @protected
  FolderExtra sse_decode_box_autoadd_folder_extra(SseDeserializer deserializer);

  @protected
  FolderManager sse_decode_box_autoadd_folder_manager(
      SseDeserializer deserializer);

  @protected
  FolderExtra sse_decode_folder_extra(SseDeserializer deserializer);

  @protected
  FolderItem sse_decode_folder_item(SseDeserializer deserializer);

  @protected
  FolderManager sse_decode_folder_manager(SseDeserializer deserializer);

  @protected
  FolderResponse sse_decode_folder_response(SseDeserializer deserializer);

  @protected
  int sse_decode_i_32(SseDeserializer deserializer);

  @protected
  PlatformInt64 sse_decode_i_64(SseDeserializer deserializer);

  @protected
  List<FolderItem> sse_decode_list_folder_item(SseDeserializer deserializer);

  @protected
  Uint8List sse_decode_list_prim_u_8_strict(SseDeserializer deserializer);

  @protected
  String? sse_decode_opt_String(SseDeserializer deserializer);

  @protected
  bool? sse_decode_opt_box_autoadd_bool(SseDeserializer deserializer);

  @protected
  FolderExtra? sse_decode_opt_box_autoadd_folder_extra(
      SseDeserializer deserializer);

  @protected
  RootFolder sse_decode_root_folder(SseDeserializer deserializer);

  @protected
  int sse_decode_u_8(SseDeserializer deserializer);

  @protected
  void sse_decode_unit(SseDeserializer deserializer);

  @protected
  void sse_encode_AnyhowException(
      AnyhowException self, SseSerializer serializer);

  @protected
  void sse_encode_String(String self, SseSerializer serializer);

  @protected
  void sse_encode_bool(bool self, SseSerializer serializer);

  @protected
  void sse_encode_box_autoadd_bool(bool self, SseSerializer serializer);

  @protected
  void sse_encode_box_autoadd_folder_extra(
      FolderExtra self, SseSerializer serializer);

  @protected
  void sse_encode_box_autoadd_folder_manager(
      FolderManager self, SseSerializer serializer);

  @protected
  void sse_encode_folder_extra(FolderExtra self, SseSerializer serializer);

  @protected
  void sse_encode_folder_item(FolderItem self, SseSerializer serializer);

  @protected
  void sse_encode_folder_manager(FolderManager self, SseSerializer serializer);

  @protected
  void sse_encode_folder_response(
      FolderResponse self, SseSerializer serializer);

  @protected
  void sse_encode_i_32(int self, SseSerializer serializer);

  @protected
  void sse_encode_i_64(PlatformInt64 self, SseSerializer serializer);

  @protected
  void sse_encode_list_folder_item(
      List<FolderItem> self, SseSerializer serializer);

  @protected
  void sse_encode_list_prim_u_8_strict(
      Uint8List self, SseSerializer serializer);

  @protected
  void sse_encode_opt_String(String? self, SseSerializer serializer);

  @protected
  void sse_encode_opt_box_autoadd_bool(bool? self, SseSerializer serializer);

  @protected
  void sse_encode_opt_box_autoadd_folder_extra(
      FolderExtra? self, SseSerializer serializer);

  @protected
  void sse_encode_root_folder(RootFolder self, SseSerializer serializer);

  @protected
  void sse_encode_u_8(int self, SseSerializer serializer);

  @protected
  void sse_encode_unit(void self, SseSerializer serializer);
}

// Section: wire_class

class RustLibWire implements BaseWire {
  RustLibWire.fromExternalLibrary(ExternalLibrary lib);
}

@JS('wasm_bindgen')
external RustLibWasmModule get wasmModule;

@JS()
@anonymous
extension type RustLibWasmModule._(JSObject _) implements JSObject {}
