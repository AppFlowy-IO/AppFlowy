import 'package:appflowy/env/cloud_env.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/user/prelude.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../widgets/widgets.dart';
import 'personal_info.dart';

class PersonalInfoSettingGroup extends StatelessWidget {
  const PersonalInfoSettingGroup({
    super.key,
    required this.userProfile,
  });

  final UserProfilePB userProfile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocProvider<SettingsUserViewBloc>(
      create: (context) => getIt<SettingsUserViewBloc>(
        param1: userProfile,
      )..add(const SettingsUserEvent.initial()),
      child: BlocSelector<SettingsUserViewBloc, SettingsUserState, String>(
        selector: (state) => state.userProfile.name,
        builder: (context, userName) {
          return MobileSettingGroup(
            groupTitle: LocaleKeys.settings_mobile_personalInfo.tr(),
            settingItemList: [
              MobileSettingItem(
                name: userName,
                subtitle: isAuthEnabled
                    ? Text(
                        userProfile.email,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                      )
                    : null,
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  showMobileBottomSheet(
                    context,
                    builder: (_) {
                      return EditUsernameBottomSheet(
                        context,
                        userName: userName,
                        onSubmitted: (value) {
                          context.read<SettingsUserViewBloc>().add(
                                SettingsUserEvent.updateUserName(
                                  value,
                                ),
                              );
                        },
                      );
                    },
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
