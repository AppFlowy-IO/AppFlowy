/// bindings for `libflowy_ffi`

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
        '${Directory.systemTemp.path}/app_flowy/libflowy_ffi.dylib');
  } else {
    if (Platform.isAndroid) return DynamicLibrary.open('libflowy_ffi.so');
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

/// C function `command_sync`.
Pointer<Uint8> sync_command(
  Pointer<Uint8> input,
  int len,
) {
  return _invoke_sync(input, len);
}

final _invoke_sync_Dart _invoke_sync =
    _dl.lookupFunction<_invoke_sync_C, _invoke_sync_Dart>('sync_command');
typedef _invoke_sync_C = Pointer<Uint8> Function(
  Pointer<Uint8> input,
  Uint64 len,
);
typedef _invoke_sync_Dart = Pointer<Uint8> Function(
  Pointer<Uint8> input,
  int len,
);

/// C function `async_query`.
void async_query(
  int port,
  Pointer<Uint8> input,
  int len,
) {
  _invoke_async_query(port, input, len);
}

final _invoke_async_query_Dart _invoke_async_query =
    _dl.lookupFunction<_invoke_async_query_C, _invoke_async_query_Dart>(
        'async_query');
typedef _invoke_async_query_C = Void Function(
  Int64 port,
  Pointer<Uint8> input,
  Uint64 len,
);
typedef _invoke_async_query_Dart = void Function(
  int port,
  Pointer<Uint8> input,
  int len,
);

/// C function `free_rust`.
void free_rust(
  Pointer<Uint8> input,
  int len,
) {
  _free_rust(input, len);
}

final _free_rust_Dart _free_rust =
    _dl.lookupFunction<_free_rust_C, _free_rust_Dart>('free_rust');
typedef _free_rust_C = Void Function(
  Pointer<Uint8> input,
  Uint64 len,
);
typedef _free_rust_Dart = void Function(
  Pointer<Uint8> input,
  int len,
);

/// C function `init_stream`.
int init_stream(int port) {
  return _init_stream(port);
}

final _init_stream_Dart _init_stream =
    _dl.lookupFunction<_init_stream_C, _init_stream_Dart>('init_stream');

typedef _init_stream_C = Int32 Function(
  Int64 port,
);
typedef _init_stream_Dart = int Function(
  int port,
);

/// C function `init_logger`.
int init_logger() {
  return _init_logger();
}

final _init_logger_Dart _init_logger =
    _dl.lookupFunction<_init_logger_C, _init_logger_Dart>('init_logger');
typedef _init_logger_C = Int64 Function();
typedef _init_logger_Dart = int Function();

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

/// C function `setup_logger`.
void setup_logger(
  Pointer ptr,
) {
  _setup_logger(ptr);
}

final _setup_logger_Dart _setup_logger =
    _dl.lookupFunction<_setup_logger_C, _setup_logger_Dart>('setup_logger');
typedef _setup_logger_C = Void Function(
  Pointer ptr,
);
typedef _setup_logger_Dart = void Function(
  Pointer ptr,
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
