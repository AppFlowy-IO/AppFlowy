#include "include/appflowy_backend/appflowy_backend_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "appflowy_flutter_backend_plugin.h"

void AppFlowyBackendPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar)
{
    appflowy_backend::AppFlowyBackendPlugin::RegisterWithRegistrar(
        flutter::PluginRegistrarManager::GetInstance()
            ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
