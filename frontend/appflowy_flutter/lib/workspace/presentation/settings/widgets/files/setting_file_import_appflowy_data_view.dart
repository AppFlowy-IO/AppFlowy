import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:appflowy/core/helpers/url_launcher.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/settings/setting_file_importer_bloc.dart';
import 'package:appflowy/workspace/presentation/home/toast.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/file_picker/file_picker_service.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ImportAppFlowyData extends StatefulWidget {
  const ImportAppFlowyData({super.key});

  @override
  State<ImportAppFlowyData> createState() => _ImportAppFlowyDataState();
}

class _ImportAppFlowyDataState extends State<ImportAppFlowyData> {
  final _fToast = FToast();
  @override
  void initState() {
    super.initState();
    _fToast.init(context);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SettingFileImportBloc(),
      child: BlocListener<SettingFileImportBloc, SettingFileImportState>(
        listener: (context, state) {
          state.successOrFail?.fold(
            (_) {
              _showToast(LocaleKeys.settings_menu_importSuccess.tr());
            },
            (_) {
              _showToast(LocaleKeys.settings_menu_importFailed.tr());
            },
          );
        },
        child: BlocBuilder<SettingFileImportBloc, SettingFileImportState>(
          builder: (context, state) {
            final List<Widget> children = [
              const ImportAppFlowyDataButton(),
              const VSpace(6),
            ];

            if (state.loadingState.isLoading()) {
              children.add(const AppFlowyDataImportingTip());
            } else {
              children.add(const AppFlowyDataImportTip());
            }

            return Column(children: children);
          },
        ),
      ),
    );
  }

  void _showToast(String message) {
    _fToast.showToast(
      child: FlowyMessageToast(message: message),
      gravity: ToastGravity.CENTER,
    );
  }
}

class AppFlowyDataImportTip extends StatelessWidget {
  const AppFlowyDataImportTip({super.key});

  final url = "https://docs.appflowy.io/docs/appflowy/product/data-storage";

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.6,
      child: RichText(
        text: TextSpan(
          children: <TextSpan>[
            TextSpan(
              text: LocaleKeys.settings_menu_importAppFlowyDataDescription.tr(),
              style: Theme.of(context).textTheme.bodySmall!,
            ),
            TextSpan(
              text: " ${LocaleKeys.settings_menu_importGuide.tr()} ",
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    decoration: TextDecoration.underline,
                  ),
              recognizer: TapGestureRecognizer()
                ..onTap = () => afLaunchUrlString(url),
            ),
          ],
        ),
      ),
    );
  }
}

class ImportAppFlowyDataButton extends StatefulWidget {
  const ImportAppFlowyDataButton({super.key});

  @override
  State<ImportAppFlowyDataButton> createState() =>
      _ImportAppFlowyDataButtonState();
}

class _ImportAppFlowyDataButtonState extends State<ImportAppFlowyDataButton> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingFileImportBloc, SettingFileImportState>(
      builder: (context, state) {
        return Column(
          children: [
            SizedBox(
              height: 40,
              child: FlowyButton(
                disable: state.loadingState.isLoading(),
                text:
                    FlowyText(LocaleKeys.settings_menu_importAppFlowyData.tr()),
                onTap: () async {
                  final path =
                      await getIt<FilePickerService>().getDirectoryPath();
                  if (path == null || !context.mounted) {
                    return;
                  }

                  context.read<SettingFileImportBloc>().add(
                        SettingFileImportEvent.importAppFlowyDataFolder(path),
                      );
                },
              ),
            ),
            if (state.loadingState.isLoading())
              const LinearProgressIndicator(minHeight: 1),
          ],
        );
      },
    );
  }
}

class AppFlowyDataImportingTip extends StatelessWidget {
  const AppFlowyDataImportingTip({super.key});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.6,
      child: RichText(
        text: TextSpan(
          children: <TextSpan>[
            TextSpan(
              text: LocaleKeys.settings_menu_importingAppFlowyDataTip.tr(),
              style: Theme.of(context).textTheme.bodySmall!,
            ),
          ],
        ),
      ),
    );
  }
}
