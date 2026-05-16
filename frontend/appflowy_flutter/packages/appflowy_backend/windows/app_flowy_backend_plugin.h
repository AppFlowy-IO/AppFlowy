#ifndef FLUTTER_PLUGIN_FLOWY_SDK_PLUGIN_H_
#define FLUTTER_PLUGIN_FLOWY_SDK_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace appflowy_backend {

class AppFlowyBackendPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  AppFlowyBackendPlugin();

  virtual ~AppFlowyBackendPlugin();

  // Disallow copy and assign.
  AppFlowyBackendPlugin(const AppFlowyBackendPlugin&) = delete;
  AppFlowyBackendPlugin& operator=(const AppFlowyBackendPlugin&) = delete;

 private:
  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace appflowy_backend

#endif  // FLUTTER_PLUGIN_FLOWY_SDK_PLUGIN_H_
