#ifndef FLUTTER_PLUGIN_FLOWY_BOARD_PLUGIN_H_
#define FLUTTER_PLUGIN_FLOWY_BOARD_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace flowy_board {

class FlowyBoardPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  FlowyBoardPlugin();

  virtual ~FlowyBoardPlugin();

  // Disallow copy and assign.
  FlowyBoardPlugin(const FlowyBoardPlugin&) = delete;
  FlowyBoardPlugin& operator=(const FlowyBoardPlugin&) = delete;

 private:
  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace flowy_board

#endif  // FLUTTER_PLUGIN_FLOWY_BOARD_PLUGIN_H_
