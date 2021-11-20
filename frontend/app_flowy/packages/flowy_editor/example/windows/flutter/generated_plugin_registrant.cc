//
//  Generated file. Do not edit.
//

#include "generated_plugin_registrant.h"

#include <flowy_editor/flowy_editor_plugin.h>
#include <url_launcher_windows/url_launcher_plugin.h>

void RegisterPlugins(flutter::PluginRegistry* registry) {
  FlowyEditorPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("FlowyEditorPlugin"));
  UrlLauncherPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("UrlLauncherPlugin"));
}
