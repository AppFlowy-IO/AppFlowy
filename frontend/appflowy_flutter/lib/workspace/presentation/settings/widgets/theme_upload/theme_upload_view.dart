import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/plugins/bloc/dynamic_plugin_bloc.dart';
import 'package:flowy_infra/plugins/bloc/dynamic_plugin_state.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'theme_upload_decoration.dart';
import 'theme_upload_failure_widget.dart';
import 'theme_upload_loading_widget.dart';
import 'upload_new_theme_widget.dart';

class ThemeUploadWidget extends StatefulWidget {
  const ThemeUploadWidget({super.key});

  static const double borderRadius = 14;
  static const double buttonFontSize = 14;
  static const Size buttonSize = Size(72, 28);
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
      state.when(
        ready: () {
          child = const UploadNewThemeWidget();
        },
        processing: () {
          child = const ThemeUploadLoadingWidget();
        },
        compilationFailure: (path) {
          child = const ThemeUploadFailureWidget();
        },
        compilationSuccess: () async {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: FlowyText.medium(
                color: Theme.of(context).colorScheme.onPrimary,
                LocaleKeys.settings_appearance_themeUpload_uploadSuccess.tr(),
              ),
            ),
          );
        },
      );
    });
  }

  Widget child = const UploadNewThemeWidget();

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DynamicPluginBloc>(
      create: (_) => DynamicPluginBloc(),
      child: BlocListener<DynamicPluginBloc, DynamicPluginState>(
        listener: listen,
        child: ThemeUploadDecoration(
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
