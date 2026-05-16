import 'package:flutter/material.dart';

import 'package:flowy_infra/plugins/bloc/dynamic_plugin_bloc.dart';
import 'package:flowy_infra/plugins/bloc/dynamic_plugin_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'theme_upload_decoration.dart';
import 'theme_upload_failure_widget.dart';
import 'theme_upload_loading_widget.dart';
import 'upload_new_theme_widget.dart';

class ThemeUploadWidget extends StatefulWidget {
  const ThemeUploadWidget({super.key});

  static const double borderRadius = 8;
  static const double buttonFontSize = 14;
  static const Size buttonSize = Size(100, 32);
  static const EdgeInsets padding = EdgeInsets.all(12.0);
  static const Size iconSize = Size.square(48);
  static const Widget elementSpacer = SizedBox(height: 12);
  static const double fadeOpacity = 0.5;
  static const Duration fadeDuration = Duration(milliseconds: 750);

  @override
  State<ThemeUploadWidget> createState() => _ThemeUploadWidgetState();
}

class _ThemeUploadWidgetState extends State<ThemeUploadWidget> {
  void listen(BuildContext context, DynamicPluginState state) {
    setState(() {
      state.whenOrNull(
        ready: (plugins) {
          child =
              const UploadNewThemeWidget(key: Key('upload_new_theme_widget'));
        },
        deletionSuccess: () {
          child =
              const UploadNewThemeWidget(key: Key('upload_new_theme_widget'));
        },
        processing: () {
          child = const ThemeUploadLoadingWidget(
            key: Key('upload_theme_loading_widget'),
          );
        },
        compilationFailure: (errorMessage) {
          child = ThemeUploadFailureWidget(
            key: const Key('upload_theme_failure_widget'),
            errorMessage: errorMessage,
          );
        },
        compilationSuccess: () {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context)
                .pop(const DynamicPluginState.compilationSuccess());
          }
        },
      );
    });
  }

  Widget child = const UploadNewThemeWidget(
    key: Key('upload_new_theme_widget'),
  );

  @override
  Widget build(BuildContext context) {
    return BlocListener<DynamicPluginBloc, DynamicPluginState>(
      listener: listen,
      child: ThemeUploadDecoration(
        child: Center(
          child: AnimatedSwitcher(
            duration: ThemeUploadWidget.fadeDuration,
            switchInCurve: Curves.easeInOutCubicEmphasized,
            child: child,
          ),
        ),
      ),
    );
  }
}
