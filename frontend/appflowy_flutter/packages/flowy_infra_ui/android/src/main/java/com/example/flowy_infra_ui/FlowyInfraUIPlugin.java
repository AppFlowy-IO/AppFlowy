package com.example.flowy_infra_ui;

import android.app.Activity;

import androidx.annotation.NonNull;

import com.example.flowy_infra_ui.event.KeyboardEventHandler;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

/** FlowyInfraUIPlugin */
public class FlowyInfraUIPlugin implements FlutterPlugin, ActivityAware, MethodCallHandler {

  // MARK: - Constant
  public static final String INFRA_UI_METHOD_CHANNEL_NAME = "flowy_infra_ui_method";
  public static final String INFRA_UI_KEYBOARD_EVENT_CHANNEL_NAME = "flowy_infra_ui_event/keyboard";

  public static final String INFRA_UI_METHOD_GET_PLATFORM_VERSION = "getPlatformVersion";

  // Method Channel
  private MethodChannel methodChannel;
  // Event Channel
  private KeyboardEventHandler keyboardEventHandler = new KeyboardEventHandler();

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    methodChannel = new MethodChannel(
            flutterPluginBinding.getBinaryMessenger(),
            INFRA_UI_METHOD_CHANNEL_NAME);
    methodChannel.setMethodCallHandler(this);

    final EventChannel keyboardEventChannel = new EventChannel(
            flutterPluginBinding.getBinaryMessenger(),
            INFRA_UI_KEYBOARD_EVENT_CHANNEL_NAME);
    keyboardEventChannel.setStreamHandler(keyboardEventHandler);
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    methodChannel.setMethodCallHandler(null);
    keyboardEventHandler.cancelObserveKeyboardAction();
  }

  @Override
  public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
    keyboardEventHandler.observeKeyboardAction(binding.getActivity());
  }

  @Override
  public void onDetachedFromActivityForConfigChanges() {
    keyboardEventHandler.cancelObserveKeyboardAction();
  }

  @Override
  public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
    keyboardEventHandler.observeKeyboardAction(binding.getActivity());
  }

  @Override
  public void onDetachedFromActivity() {
    keyboardEventHandler.cancelObserveKeyboardAction();
  }

  // MARK: - Method Channel

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    if (call.method.equals(INFRA_UI_METHOD_GET_PLATFORM_VERSION)) {
      result.success("Android " + android.os.Build.VERSION.RELEASE);
    } else {
      result.notImplemented();
    }
  }
}
