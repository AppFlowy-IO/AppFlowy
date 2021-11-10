//
//  Generated file. Do not edit.
//

import FlutterMacOS
import Foundation

import flowy_editor
import flowy_infra_ui
import flowy_sdk
import package_info_plus_macos
import path_provider_macos
import sqflite
import url_launcher_macos
import window_size

func RegisterGeneratedPlugins(registry: FlutterPluginRegistry) {
  FlowyEditorPlugin.register(with: registry.registrar(forPlugin: "FlowyEditorPlugin"))
  FlowyInfraUIPlugin.register(with: registry.registrar(forPlugin: "FlowyInfraUIPlugin"))
  FlowySdkPlugin.register(with: registry.registrar(forPlugin: "FlowySdkPlugin"))
  FLTPackageInfoPlusPlugin.register(with: registry.registrar(forPlugin: "FLTPackageInfoPlusPlugin"))
  PathProviderPlugin.register(with: registry.registrar(forPlugin: "PathProviderPlugin"))
  SqflitePlugin.register(with: registry.registrar(forPlugin: "SqflitePlugin"))
  UrlLauncherPlugin.register(with: registry.registrar(forPlugin: "UrlLauncherPlugin"))
  WindowSizePlugin.register(with: registry.registrar(forPlugin: "WindowSizePlugin"))
}
