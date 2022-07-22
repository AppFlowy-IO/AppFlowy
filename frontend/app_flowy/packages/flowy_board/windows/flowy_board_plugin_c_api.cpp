#include "include/flowy_board/flowy_board_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "flowy_board_plugin.h"

void FlowyBoardPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  flowy_board::FlowyBoardPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
