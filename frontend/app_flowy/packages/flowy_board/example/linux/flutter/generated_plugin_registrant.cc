//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <flowy_board/flowy_board_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) flowy_board_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "FlowyBoardPlugin");
  flowy_board_plugin_register_with_registrar(flowy_board_registrar);
}
