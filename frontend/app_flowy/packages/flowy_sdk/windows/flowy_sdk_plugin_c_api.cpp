#include "include/flowy_sdk/flowy_sdk_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "flowy_sdk_plugin.h"

void FlowySdkPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  flowy_sdk::FlowySdkPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
