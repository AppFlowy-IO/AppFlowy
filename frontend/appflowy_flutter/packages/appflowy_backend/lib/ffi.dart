/// bindings for `libdart_ffi`

import 'dart:ffi';
import 'dart:io';
// ignore: import_of_legacy_library_into_null_safe
import 'package:ffi/ffi.dart' as ffi;
import 'package:flutter/foundation.dart' as Foundation;

// ignore_for_file: unused_import, camel_case_types, non_constant_identifier_names
final DynamicLibrary _dart_ffi_lib = _open();

/// Reference to the Dynamic Library, it should be only used for low-level access
final DynamicLibrary dl = _dart_ffi_lib;
DynamicLibrary _open() {
  if (Platform.environment.containsKey('FLUTTER_TEST')) {
    final prefix = "${Directory.current.path}/.sandbox";
    if (Platform.isLinux)
      return DynamicLibrary.open('${prefix}/libdart_ffi.so');
    if (Platform.isAndroid)
      return DynamicLibrary.open('${prefix}/libdart_ffi.so');
    if (Platform.isMacOS)
      return DynamicLibrary.open('${prefix}/libdart_ffi.dylib');
    if (Platform.isIOS) return DynamicLibrary.open('${prefix}/libdart_ffi.a');
    if (Platform.isWindows)
      return DynamicLibrary.open('${prefix}/dart_ffi.dll');
  } else {
    if (Platform.isLinux) return DynamicLibrary.open('libdart_ffi.so');
    if (Platform.isAndroid) return DynamicLibrary.open('libdart_ffi.so');
    if (Platform.isMacOS) return DynamicLibrary.executable();
    if (Platform.isIOS) return DynamicLibrary.executable();
    if (Platform.isWindows) return DynamicLibrary.open('dart_ffi.dll');
  }

  throw UnsupportedError('This platform is not supported.');
}

/// C function `async_event`.
void async_event(
  int port,
  Pointer<Uint8> input,
  int len,
) {
  _invoke_async(port, input, len);
}

final _invoke_async_Dart _invoke_async = _dart_ffi_lib
    .lookupFunction<_invoke_async_C, _invoke_async_Dart>('async_event');
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

/// C function `sync_event`.
Pointer<Uint8> sync_event(
  Pointer<Uint8> input,
  int len,
) {
  return _invoke_sync(input, len);
}

final _invoke_sync_Dart _invoke_sync = _dart_ffi_lib
    .lookupFunction<_invoke_sync_C, _invoke_sync_Dart>('sync_event');
typedef _invoke_sync_C = Pointer<Uint8> Function(
  Pointer<Uint8> input,
  Uint64 len,
);
typedef _invoke_sync_Dart = Pointer<Uint8> Function(
  Pointer<Uint8> input,
  int len,
);

/// C function `init_sdk`.
int init_sdk(
  int port,
  Pointer<ffi.Utf8> data,
) {
  return _init_sdk(port, data);
}

final _init_sdk_Dart _init_sdk =
    _dart_ffi_lib.lookupFunction<_init_sdk_C, _init_sdk_Dart>('init_sdk');
typedef _init_sdk_C = Int64 Function(
  Int64 port,
  Pointer<ffi.Utf8> path,
);
typedef _init_sdk_Dart = int Function(
  int port,
  Pointer<ffi.Utf8> path,
);

/// C function `init_stream`.
int set_stream_port(int port) {
  return _set_stream_port(port);
}

final _set_stream_port_Dart _set_stream_port =
    _dart_ffi_lib.lookupFunction<_set_stream_port_C, _set_stream_port_Dart>(
        'set_stream_port');

typedef _set_stream_port_C = Int32 Function(
  Int64 port,
);
typedef _set_stream_port_Dart = int Function(
  int port,
);

/// C function `set log stream port`.
int set_log_stream_port(int port) {
  return _set_log_stream_port(port);
}

final _set_log_stream_port_Dart _set_log_stream_port = _dart_ffi_lib
    .lookupFunction<_set_log_stream_port_C, _set_log_stream_port_Dart>(
        'set_log_stream_port');

typedef _set_log_stream_port_C = Int32 Function(
  Int64 port,
);
typedef _set_log_stream_port_Dart = int Function(
  int port,
);

/// C function `link_me_please`.
void link_me_please() {
  _link_me_please();
}

final _link_me_please_Dart _link_me_please = _dart_ffi_lib
    .lookupFunction<_link_me_please_C, _link_me_please_Dart>('link_me_please');
typedef _link_me_please_C = Void Function();
typedef _link_me_please_Dart = void Function();

/// Binding to `allo-isolate` crate
void store_dart_post_cobject(
  Pointer<NativeFunction<Int8 Function(Int64, Pointer<Dart_CObject>)>> ptr,
) {
  _store_dart_post_cobject(ptr);
}

final _store_dart_post_cobject_Dart _store_dart_post_cobject = _dart_ffi_lib
    .lookupFunction<_store_dart_post_cobject_C, _store_dart_post_cobject_Dart>(
        'store_dart_post_cobject');
typedef _store_dart_post_cobject_C = Void Function(
  Pointer<NativeFunction<Int8 Function(Int64, Pointer<Dart_CObject>)>> ptr,
);
typedef _store_dart_post_cobject_Dart = void Function(
  Pointer<NativeFunction<Int8 Function(Int64, Pointer<Dart_CObject>)>> ptr,
);

void rust_log(
  int level,
  Pointer<ffi.Utf8> data,
) {
  _invoke_rust_log(level, data);
}

final _invoke_rust_log_Dart _invoke_rust_log = _dart_ffi_lib
    .lookupFunction<_invoke_rust_log_C, _invoke_rust_log_Dart>('rust_log');
typedef _invoke_rust_log_C = Void Function(
  Int64 level,
  Pointer<ffi.Utf8> data,
);
typedef _invoke_rust_log_Dart = void Function(
  int level,
  Pointer<ffi.Utf8>,
);

/// C function `set_env`.
void set_env(
  Pointer<ffi.Utf8> data,
) {
  _set_env(data);
}

final _set_env_Dart _set_env =
    _dart_ffi_lib.lookupFunction<_set_env_C, _set_env_Dart>('set_env');
typedef _set_env_C = Void Function(
  Pointer<ffi.Utf8> data,
);
typedef _set_env_Dart = void Function(
  Pointer<ffi.Utf8> data,
);
