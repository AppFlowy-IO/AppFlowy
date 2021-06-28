/// bindings for `libdart_ffi`

import 'dart:ffi';
import 'dart:io';
// ignore: import_of_legacy_library_into_null_safe
import 'package:ffi/ffi.dart' as ffi;
import 'package:flutter/foundation.dart' as Foundation;

// ignore_for_file: unused_import, camel_case_types, non_constant_identifier_names
final DynamicLibrary _dl = _open();

/// Reference to the Dynamic Library, it should be only used for low-level access
final DynamicLibrary dl = _dl;
DynamicLibrary _open() {
  if (is_tester()) {
    return DynamicLibrary.open(
        '${Directory.systemTemp.path}/app_flowy/libdart_ffi.dylib');
  } else {
    if (Platform.isAndroid) return DynamicLibrary.open('libdart_ffi.so');
    if (Platform.isMacOS) return DynamicLibrary.executable();
    if (Platform.isIOS) return DynamicLibrary.executable();
    throw UnsupportedError('This platform is not supported.');
  }
}

/// C function `async_command`.
void async_command(
  int port,
  Pointer<Uint8> input,
  int len,
) {
  _invoke_async(port, input, len);
}

final _invoke_async_Dart _invoke_async =
    _dl.lookupFunction<_invoke_async_C, _invoke_async_Dart>('async_command');
typedef _invoke_async_C = Void Function(
  Int64 port,
  Pointer<Uint8> input,
  Uint64 len,
);
typedef _invoke_async_Dart = void Function(
  int port,
  Pointer<Uint8> input,
  int len,
);

/// C function `init_sdk`.
int init_sdk(
  Pointer<ffi.Utf8> path,
) {
  return _init_sdk(path);
}

final _init_sdk_Dart _init_sdk =
    _dl.lookupFunction<_init_sdk_C, _init_sdk_Dart>('init_sdk');
typedef _init_sdk_C = Int64 Function(
  Pointer<ffi.Utf8> path,
);
typedef _init_sdk_Dart = int Function(
  Pointer<ffi.Utf8> path,
);

/// C function `link_me_please`.
void link_me_please() {
  _link_me_please();
}

final _link_me_please_Dart _link_me_please = _dl
    .lookupFunction<_link_me_please_C, _link_me_please_Dart>('link_me_please');
typedef _link_me_please_C = Void Function();
typedef _link_me_please_Dart = void Function();

/// Binding to `allo-isolate` crate
void store_dart_post_cobject(
  Pointer<NativeFunction<Int8 Function(Int64, Pointer<Dart_CObject>)>> ptr,
) {
  _store_dart_post_cobject(ptr);
}

final _store_dart_post_cobject_Dart _store_dart_post_cobject = _dl
    .lookupFunction<_store_dart_post_cobject_C, _store_dart_post_cobject_Dart>(
        'store_dart_post_cobject');
typedef _store_dart_post_cobject_C = Void Function(
  Pointer<NativeFunction<Int8 Function(Int64, Pointer<Dart_CObject>)>> ptr,
);
typedef _store_dart_post_cobject_Dart = void Function(
  Pointer<NativeFunction<Int8 Function(Int64, Pointer<Dart_CObject>)>> ptr,
);

bool is_tester() {
  if (Foundation.kDebugMode) {
    // ignore: unnecessary_null_comparison
    if (Platform.executable == null) {
      return false;
    } else {
      return Platform.executable.contains("tester");
    }
  } else {
    return false;
  }
}
