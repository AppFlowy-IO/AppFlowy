package com.example.flowy_infra_ui.event;

import android.app.Activity;
import android.os.Build;
import android.view.View;

import androidx.annotation.RequiresApi;
import androidx.core.view.OnApplyWindowInsetsListener;
import androidx.core.view.ViewCompat;
import androidx.core.view.WindowInsetsCompat;

import io.flutter.plugin.common.EventChannel;

public class KeyboardEventHandler implements EventChannel.StreamHandler {
    private EventChannel.EventSink eventSink;
    private View rootView;
    private boolean isKeyboardShow = false;

    @Override
    public void onListen(Object arguments, EventChannel.EventSink events) {
        eventSink = events;
    }

    @Override
    public void onCancel(Object arguments) {
        eventSink = null;
    }

    // MARK: - Helper

    @RequiresApi(Build.VERSION_CODES.R)
    public void observeKeyboardAction(Activity activity) {
        rootView = activity.findViewById(android.R.id.content);

        ViewCompat.setOnApplyWindowInsetsListener(rootView, new OnApplyWindowInsetsListener() {
            @Override
            public WindowInsetsCompat onApplyWindowInsets(View view, WindowInsetsCompat insets) {
                isKeyboardShow = insets.isVisible(WindowInsetsCompat.Type.ime());
                if (eventSink != null) {
                    eventSink.success(isKeyboardShow);
                }
                return insets;
            }
        });
    }

    public void cancelObserveKeyboardAction() {
        if (rootView != null) {
            ViewCompat.setOnApplyWindowInsetsListener(rootView, null);
            rootView = null;
        }
    }
}
