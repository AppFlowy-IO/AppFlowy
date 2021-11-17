//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <flowy_editor/flowy_editor_plugin.h>
#include <flowy_infra_ui/flowy_infra_u_i_plugin.h>
#include <flowy_sdk/flowy_sdk_plugin.h>
#include <url_launcher_windows/url_launcher_windows.h>
#include <window_size/window_size_plugin.h>

void RegisterPlugins(flutter::PluginRegistry* registry) {
  FlowyEditorPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("FlowyEditorPlugin"));
  FlowyInfraUIPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("FlowyInfraUIPlugin"));
  FlowySdkPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("FlowySdkPlugin"));
  UrlLauncherWindowsRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("UrlLauncherWindows"));
  WindowSizePluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("WindowSizePlugin"));
}
