//
//  Generated file. Do not edit.
//

import FlutterMacOS
import Foundation

import connectivity_plus_macos
import device_info_plus_macos
import flowy_infra_ui
import flowy_sdk
import hotkey_manager
import package_info_plus_macos
import path_provider_macos
import rich_clipboard_macos
import shared_preferences_macos
import url_launcher_macos
import window_size

func RegisterGeneratedPlugins(registry: FlutterPluginRegistry) {
  ConnectivityPlugin.register(with: registry.registrar(forPlugin: "ConnectivityPlugin"))
  DeviceInfoPlusMacosPlugin.register(with: registry.registrar(forPlugin: "DeviceInfoPlusMacosPlugin"))
  FlowyInfraUIPlugin.register(with: registry.registrar(forPlugin: "FlowyInfraUIPlugin"))
  FlowySdkPlugin.register(with: registry.registrar(forPlugin: "FlowySdkPlugin"))
  HotkeyManagerPlugin.register(with: registry.registrar(forPlugin: "HotkeyManagerPlugin"))
  FLTPackageInfoPlusPlugin.register(with: registry.registrar(forPlugin: "FLTPackageInfoPlusPlugin"))
  PathProviderPlugin.register(with: registry.registrar(forPlugin: "PathProviderPlugin"))
  RichClipboardPlugin.register(with: registry.registrar(forPlugin: "RichClipboardPlugin"))
  SharedPreferencesPlugin.register(with: registry.registrar(forPlugin: "SharedPreferencesPlugin"))
  UrlLauncherPlugin.register(with: registry.registrar(forPlugin: "UrlLauncherPlugin"))
  WindowSizePlugin.register(with: registry.registrar(forPlugin: "WindowSizePlugin"))
}
