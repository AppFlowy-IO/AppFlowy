import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:flowy_infra/plugins/models/flowy_dynamic_plugin.dart';
import 'package:flowy_infra/plugins/service/location_service.dart';
import 'package:flowy_infra/plugins/service/plugin_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

import '../../file_picker/file_picker_impl.dart';
import 'dynamic_plugin_event.dart';
import 'dynamic_plugin_state.dart';

class DynamicPluginBloc extends Bloc<DynamicPluginEvent, DynamicPluginState> {
  DynamicPluginBloc({FilePicker? filePicker})
      : _filePicker = filePicker ?? FilePicker(),
        super(const DynamicPluginState.uninitialized()) {
    on<DynamicPluginEvent>(dispatch);
    add(DynamicPluginEvent.load());
  }

  final FilePicker _filePicker;

  Future<void> dispatch(
      DynamicPluginEvent event, Emitter<DynamicPluginState> emit) async {
    await event.when(
      addPlugin: () => addPlugin(emit),
      removePlugin: (name) => removePlugin(emit, name),
      load: () => onLoadRequested(emit),
    );
  }

  Future<void> onLoadRequested(Emitter<DynamicPluginState> emit) async {
    await emitReady(emit);
  }

  Future<void> emitReady(Emitter<DynamicPluginState> emit) async {
    final service = await FlowyPluginService.instance;
    emit(DynamicPluginState.ready(plugins: await service.plugins));
  }

  Future<void> addPlugin(Emitter<DynamicPluginState> emit) async {
    if (kIsWeb) {
      throw PlatformException(
        code: "Exception: Picking files is not supported on the web",
      );
    }

    emit(const DynamicPluginState.processing());

    // get the plugin source
    final result = await _filePicker.getDirectoryPath();

    if (result == null) {
      await emitReady(emit);
      return;
    }

    // null assert should be valid every time here because we throw an error if the app is deployed to the web.
    final directory = Directory(result);

    // try to compile the plugin before we add it to the registry.
    final plugin = await FlowyDynamicPlugin.tryCompile(src: directory);
    if (plugin == null) {
      emit(DynamicPluginState.compilationFailure(path: directory.path));
      return;
    }

    // add the plugin to the registry
    final path = [
      (await PluginLocationService.location).path,
      p.basename(directory.path),
    ].join(Platform.pathSeparator);

    copyDirectorySync(directory, Directory(path));
    emit(const DynamicPluginState.compilationSuccess());
    await emitReady(emit);
  }

  Future<void> removePlugin(
      Emitter<DynamicPluginState> emit, String name) async {
    if (kIsWeb) {
      throw PlatformException(
        code: "Exception: Picking files is not supported on the web",
      );
    }

    emit(const DynamicPluginState.processing());

    final service = await FlowyPluginService.instance;
    final plugins = await service.plugins;
    final targets = plugins.where((element) => element.name == name);
    // this shouldn't happen, but if it does, we consider the plugin to be removed.
    if (targets.isEmpty) {
      return;
    }

    // There should only be one plugin available, but iterate through them anyway.
    for (final target in targets) {
      try {
        final directory = Directory(target.path);
        await directory.delete(recursive: true);
      } on Exception {
        emit(DynamicPluginState.deletionFailure(path: target.path));
        return;
      }
    }
    emit(const DynamicPluginState.deletionSuccess());
    await emitReady(emit);
  }

  void copyDirectorySync(Directory source, Directory destination) {
    /// create destination folder if not exist
    if (!destination.existsSync()) {
      destination.createSync(recursive: true);
    }

    /// get all files from source (recursive: false is important here)
    source.listSync(recursive: false).forEach(
      (entity) {
        final newPath = [
          destination.path,
          p.basename(entity.path),
        ].join(Platform.pathSeparator);
        if (entity is File) {
          entity.copySync(newPath);
        } else if (entity is Directory) {
          copyDirectorySync(entity, Directory(newPath));
        }
      },
    );
  }
}
