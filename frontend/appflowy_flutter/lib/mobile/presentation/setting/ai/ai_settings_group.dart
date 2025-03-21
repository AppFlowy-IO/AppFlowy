import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/show_mobile_bottom_sheet.dart';
import 'package:appflowy/mobile/presentation/setting/widgets/mobile_setting_group_widget.dart';
import 'package:appflowy/mobile/presentation/setting/widgets/mobile_setting_item_widget.dart';
import 'package:appflowy/mobile/presentation/widgets/flowy_option_tile.dart';
import 'package:appflowy/workspace/application/settings/ai/settings_ai_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/workspace.pbenum.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class AiSettingsGroup extends StatelessWidget {
  const AiSettingsGroup({
    super.key,
    required this.userProfile,
    required this.workspaceId,
    this.currentWorkspaceMemberRole,
  });

  final UserProfilePB userProfile;
  final String workspaceId;
  final AFRolePB? currentWorkspaceMemberRole;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocProvider(
      create: (context) => SettingsAIBloc(
        userProfile,
        workspaceId,
        currentWorkspaceMemberRole,
      )..add(const SettingsAIEvent.started()),
      child: BlocBuilder<SettingsAIBloc, SettingsAIState>(
        builder: (context, state) {
          return MobileSettingGroup(
            groupTitle: LocaleKeys.settings_aiPage_title.tr(),
            settingItemList: [
              MobileSettingItem(
                name: LocaleKeys.settings_aiPage_keys_llmModelType.tr(),
                trailing: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 200),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: FlowyText(
                          state.selectedAIModel,
                          color: theme.colorScheme.onSurface,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                ),
                onTap: () => _onLLMModelTypeTap(context, state),
              ),
              // enable AI search if needed
              // MobileSettingItem(
              //   name: LocaleKeys.settings_aiPage_keys_enableAISearchTitle.tr(),
              //   trailing: const Icon(
              //     Icons.chevron_right,
              //   ),
              //   onTap: () => context.push(AppFlowyCloudPage.routeName),
              // ),
            ],
          );
        },
      ),
    );
  }

  void _onLLMModelTypeTap(BuildContext context, SettingsAIState state) {
    final availableModels = state.availableModels;
    showMobileBottomSheet(
      context,
      showHeader: true,
      showDragHandle: true,
      showDivider: false,
      title: LocaleKeys.settings_aiPage_keys_llmModelType.tr(),
      builder: (_) {
        return Column(
          children: availableModels
              .mapIndexed(
                (index, model) => FlowyOptionTile.checkbox(
                  text: model,
                  showTopBorder: index == 0,
                  isSelected: state.selectedAIModel == model,
                  onTap: () {
                    context
                        .read<SettingsAIBloc>()
                        .add(SettingsAIEvent.selectModel(model));
                    context.pop();
                  },
                ),
              )
              .toList(),
        );
      },
    );
  }
}
