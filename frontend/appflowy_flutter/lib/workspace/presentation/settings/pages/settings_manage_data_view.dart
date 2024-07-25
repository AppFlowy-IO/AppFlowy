import 'dart:async';

import 'package:appflowy/core/helpers/url_launcher.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/shared/appflowy_cache_manager.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/startup/tasks/rust_sdk.dart';
import 'package:appflowy/util/theme_extension.dart';
import 'package:appflowy/workspace/application/settings/setting_file_importer_bloc.dart';
import 'package:appflowy/workspace/application/settings/settings_location_cubit.dart';
import 'package:appflowy/workspace/presentation/home/toast.dart';
import 'package:appflowy/workspace/presentation/settings/pages/fix_data_widget.dart';
import 'package:appflowy/workspace/presentation/settings/shared/setting_action.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_body.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_category.dart';
import 'package:appflowy/workspace/presentation/settings/shared/single_setting_action.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/files/settings_export_file_widget.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/file_picker/file_picker_service.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';

class SettingsManageDataView extends StatelessWidget {
  const SettingsManageDataView({super.key, required this.userProfile});

  final UserProfilePB userProfile;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SettingsLocationCubit>(
      create: (_) => SettingsLocationCubit(),
      child: BlocBuilder<SettingsLocationCubit, SettingsLocationState>(
        builder: (context, state) {
          return SettingsBody(
            title: LocaleKeys.settings_manageDataPage_title.tr(),
            description: LocaleKeys.settings_manageDataPage_description.tr(),
            children: [
              SettingsCategory(
                title:
                    LocaleKeys.settings_manageDataPage_dataStorage_title.tr(),
                tooltip:
                    LocaleKeys.settings_manageDataPage_dataStorage_tooltip.tr(),
                actions: [
                  if (state.mapOrNull(didReceivedPath: (_) => true) == true)
                    SettingAction(
                      tooltip: LocaleKeys
                          .settings_manageDataPage_dataStorage_actions_resetTooltip
                          .tr(),
                      icon: const FlowySvg(
                        FlowySvgs.restore_s,
                        size: Size.square(20),
                      ),
                      label: LocaleKeys.settings_common_reset.tr(),
                      onPressed: () => showConfirmDialog(
                        context: context,
                        title: LocaleKeys
                            .settings_manageDataPage_dataStorage_resetDialog_title
                            .tr(),
                        description: LocaleKeys
                            .settings_manageDataPage_dataStorage_resetDialog_description
                            .tr(),
                        confirmLabel: LocaleKeys.button_confirm.tr(),
                        onConfirm: () async {
                          final directory =
                              await appFlowyApplicationDataDirectory();
                          final path = directory.path;
                          if (!context.mounted ||
                              state.mapOrNull(didReceivedPath: (e) => e.path) ==
                                  path) {
                            return;
                          }

                          await context
                              .read<SettingsLocationCubit>()
                              .resetDataStoragePathToApplicationDefault();
                          await runAppFlowy(isAnon: true);
                        },
                      ),
                    ),
                ],
                children: state
                    .map(
                      initial: (_) => [const CircularProgressIndicator()],
                      didReceivedPath: (event) => [
                        _CurrentPath(path: event.path),
                        _DataPathActions(currentPath: event.path),
                      ],
                    )
                    .toList(),
              ),
              SettingsCategory(
                title: LocaleKeys.settings_manageDataPage_importData_title.tr(),
                tooltip:
                    LocaleKeys.settings_manageDataPage_importData_tooltip.tr(),
                children: const [_ImportDataField()],
              ),
              if (kDebugMode) ...[
                SettingsCategory(
                  title: LocaleKeys.settings_files_exportData.tr(),
                  children: const [
                    SettingsExportFileWidget(),
                    FixDataWidget(),
                  ],
                ),
              ],
              SettingsCategory(
                title: LocaleKeys.settings_manageDataPage_cache_title.tr(),
                children: [
                  SingleSettingAction(
                    labelMaxLines: 4,
                    label: LocaleKeys.settings_manageDataPage_cache_description
                        .tr(),
                    buttonLabel:
                        LocaleKeys.settings_manageDataPage_cache_title.tr(),
                    onPressed: () {
                      showCancelAndConfirmDialog(
                        context: context,
                        title: LocaleKeys
                            .settings_manageDataPage_cache_dialog_title
                            .tr(),
                        description: LocaleKeys
                            .settings_manageDataPage_cache_dialog_description
                            .tr(),
                        confirmLabel: LocaleKeys.button_ok.tr(),
                        onConfirm: () async {
                          // clear all cache
                          await getIt<FlowyCacheManager>().clearAllCache();

                          // check the workspace and space health
                          await WorkspaceDataManager.checkViewHealth(
                            dryRun: false,
                          );

                          if (context.mounted) {
                            showToastNotification(
                              context,
                              message: LocaleKeys
                                  .settings_manageDataPage_cache_dialog_successHint
                                  .tr(),
                            );
                          }
                        },
                      );
                    },
                  ),
                ],
              ),
              // Uncomment if we need to enable encryption
              //   if (userProfile.authenticator == AuthenticatorPB.Supabase) ...[
              //     const SettingsCategorySpacer(),
              //     BlocProvider(
              //       create: (_) => EncryptSecretBloc(user: userProfile),
              //       child: SettingsCategory(
              //         title: LocaleKeys.settings_manageDataPage_encryption_title
              //             .tr(),
              //         tooltip: LocaleKeys
              //             .settings_manageDataPage_encryption_tooltip
              //             .tr(),
              //         description: userProfile.encryptionType ==
              //                 EncryptionTypePB.NoEncryption
              //             ? LocaleKeys
              //                 .settings_manageDataPage_encryption_descriptionNoEncryption
              //                 .tr()
              //             : LocaleKeys
              //                 .settings_manageDataPage_encryption_descriptionEncrypted
              //                 .tr(),
              //         children: [_EncryptDataSetting(userProfile: userProfile)],
              //       ),
              //     ),
              //   ],
            ],
          );
        },
      ),
    );
  }
}

// class _EncryptDataSetting extends StatelessWidget {
//   const _EncryptDataSetting({required this.userProfile});

//   final UserProfilePB userProfile;

//   @override
//   Widget build(BuildContext context) {
//     return BlocProvider<EncryptSecretBloc>.value(
//       value: context.read<EncryptSecretBloc>(),
//       child: BlocBuilder<EncryptSecretBloc, EncryptSecretState>(
//         builder: (context, state) {
//           if (state.loadingState?.isLoading() == true) {
//             return const Row(
//               children: [
//                 SizedBox(
//                   width: 20,
//                   height: 20,
//                   child: CircularProgressIndicator(
//                     strokeWidth: 3,
//                   ),
//                 ),
//                 HSpace(16),
//                 FlowyText.medium(
//                   'Encrypting data...',
//                   fontSize: 14,
//                 ),
//               ],
//             );
//           }

//           if (userProfile.encryptionType == EncryptionTypePB.NoEncryption) {
//             return Row(
//               children: [
//                 SizedBox(
//                   height: 42,
//                   child: FlowyTextButton(
//                     LocaleKeys.settings_manageDataPage_encryption_action.tr(),
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 24,
//                       vertical: 12,
//                     ),
//                     fontWeight: FontWeight.w600,
//                     radius: BorderRadius.circular(12),
//                     fillColor: Theme.of(context).colorScheme.primary,
//                     hoverColor: const Color(0xFF005483),
//                     fontHoverColor: Colors.white,
//                     onPressed: () => SettingsAlertDialog(
//                       title: LocaleKeys
//                           .settings_manageDataPage_encryption_dialog_title
//                           .tr(),
//                       subtitle: LocaleKeys
//                           .settings_manageDataPage_encryption_dialog_description
//                           .tr(),
//                       confirmLabel: LocaleKeys
//                           .settings_manageDataPage_encryption_dialog_title
//                           .tr(),
//                       implyLeading: true,
//                       // Generate a secret one time for the user
//                       confirm: () => context
//                           .read<EncryptSecretBloc>()
//                           .add(const EncryptSecretEvent.setEncryptSecret('')),
//                     ).show(context),
//                   ),
//                 ),
//               ],
//             );
//           }
//           // Show encryption secret for copy/save
//           return const SizedBox.shrink();
//         },
//       ),
//     );
//   }
// }

class _ImportDataField extends StatefulWidget {
  const _ImportDataField();

  @override
  State<_ImportDataField> createState() => _ImportDataFieldState();
}

class _ImportDataFieldState extends State<_ImportDataField> {
  final _fToast = FToast();

  @override
  void initState() {
    super.initState();
    _fToast.init(context);
  }

  @override
  void dispose() {
    _fToast.removeQueuedCustomToasts();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SettingFileImportBloc>(
      create: (context) => SettingFileImportBloc(),
      child: BlocConsumer<SettingFileImportBloc, SettingFileImportState>(
        listenWhen: (previous, current) =>
            previous.successOrFail != current.successOrFail,
        listener: (_, state) => state.successOrFail?.fold(
          (_) => _showToast(LocaleKeys.settings_menu_importSuccess.tr()),
          (_) => _showToast(LocaleKeys.settings_menu_importFailed.tr()),
        ),
        builder: (context, state) {
          return SingleSettingAction(
            label:
                LocaleKeys.settings_manageDataPage_importData_description.tr(),
            labelMaxLines: 2,
            buttonLabel:
                LocaleKeys.settings_manageDataPage_importData_action.tr(),
            onPressed: () async {
              final path = await getIt<FilePickerService>().getDirectoryPath();
              if (path == null || !context.mounted) {
                return;
              }

              context
                  .read<SettingFileImportBloc>()
                  .add(SettingFileImportEvent.importAppFlowyDataFolder(path));
            },
          );
        },
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

class _CurrentPath extends StatefulWidget {
  const _CurrentPath({required this.path});

  final String path;

  @override
  State<_CurrentPath> createState() => _CurrentPathState();
}

class _CurrentPathState extends State<_CurrentPath> {
  Timer? linkCopiedTimer;
  bool showCopyMessage = false;

  @override
  void dispose() {
    linkCopiedTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLM = Theme.of(context).isLightMode;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: (_) => _copyLink(widget.path),
                child: FlowyHover(
                  style: const HoverStyle.transparent(),
                  resetHoverOnRebuild: false,
                  builder: (_, isHovering) => FlowyText.regular(
                    widget.path,
                    lineHeight: 1.5,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    decoration: isHovering ? TextDecoration.underline : null,
                    color: isLM
                        ? const Color(0xFF005483)
                        : Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
            const HSpace(8),
            showCopyMessage
                ? SizedBox(
                    height: 36,
                    child: FlowyTextButton(
                      LocaleKeys
                          .settings_manageDataPage_dataStorage_actions_copiedHint
                          .tr(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      fontWeight: FontWeight.w500,
                      radius: BorderRadius.circular(12),
                      fillColor: AFThemeExtension.of(context).tint7,
                      hoverColor: AFThemeExtension.of(context).tint7,
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.only(left: 100),
                    child: SettingAction(
                      tooltip: LocaleKeys
                          .settings_manageDataPage_dataStorage_actions_copy
                          .tr(),
                      icon: const FlowySvg(
                        FlowySvgs.copy_s,
                        size: Size.square(24),
                      ),
                      onPressed: () => _copyLink(widget.path),
                    ),
                  ),
          ],
        ),
      ],
    );
  }

  void _copyLink(String? path) {
    AppFlowyClipboard.setData(text: path);
    setState(() => showCopyMessage = true);
    linkCopiedTimer?.cancel();
    linkCopiedTimer = Timer(
      const Duration(milliseconds: 300),
      () => mounted ? setState(() => showCopyMessage = false) : null,
    );
  }
}

class _DataPathActions extends StatelessWidget {
  const _DataPathActions({required this.currentPath});

  final String currentPath;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          height: 42,
          child: FlowyTextButton(
            LocaleKeys.settings_manageDataPage_dataStorage_actions_change.tr(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            fontWeight: FontWeight.w600,
            radius: BorderRadius.circular(12),
            fillColor: Theme.of(context).colorScheme.primary,
            hoverColor: const Color(0xFF005483),
            fontHoverColor: Colors.white,
            onPressed: () async {
              final path = await getIt<FilePickerService>().getDirectoryPath();
              if (!context.mounted || path == null || currentPath == path) {
                return;
              }

              await context.read<SettingsLocationCubit>().setCustomPath(path);
              await runAppFlowy(isAnon: true);

              if (context.mounted) Navigator.of(context).pop();
            },
          ),
        ),
        const HSpace(16),
        SettingAction(
          tooltip: LocaleKeys
              .settings_manageDataPage_dataStorage_actions_openTooltip
              .tr(),
          label:
              LocaleKeys.settings_manageDataPage_dataStorage_actions_open.tr(),
          icon: const FlowySvg(FlowySvgs.folder_m, size: Size.square(20)),
          onPressed: () => afLaunchUrl(Uri.file(currentPath)),
        ),
      ],
    );
  }
}
