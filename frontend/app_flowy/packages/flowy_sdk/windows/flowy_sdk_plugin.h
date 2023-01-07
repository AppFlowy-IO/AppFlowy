#ifndef FLUTTER_PLUGIN_FLOWY_SDK_PLUGIN_H_
#define FLUTTER_PLUGIN_FLOWY_SDK_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace flowy_sdk {

class FlowySdkPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  FlowySdkPlugin();

  virtual ~FlowySdkPlugin();

  // Disallow copy and assign.
  FlowySdkPlugin(const FlowySdkPlugin&) = delete;
  FlowySdkPlugin& operator=(const FlowySdkPlugin&) = delete;

 private:
  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace flowy_sdk

#endif  // FLUTTER_PLUGIN_FLOWY_SDK_PLUGIN_H_
