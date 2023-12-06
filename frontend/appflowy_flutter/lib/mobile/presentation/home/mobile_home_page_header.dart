import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/home/mobile_home_setting_page.dart';
import 'package:appflowy/plugins/base/emoji/emoji_picker_screen.dart';
import 'package:appflowy/plugins/base/icon/icon_picker.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/user/settings_user_bloc.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/settings_user_view.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class MobileHomePageHeader extends StatelessWidget {
  const MobileHomePageHeader({
    super.key,
    required this.userProfile,
  });

  final UserProfilePB userProfile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocProvider(
      create: (context) => getIt<SettingsUserViewBloc>(param1: userProfile)
        ..add(const SettingsUserEvent.initial()),
      child: BlocBuilder<SettingsUserViewBloc, SettingsUserState>(
        builder: (context, state) {
          final userIcon = state.userProfile.iconUrl;
          return ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Row(
              children: [
                _UserIcon(userIcon: userIcon),
                const HSpace(12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const FlowyText.medium(
                        'AppFlowy',
                        fontSize: 18,
                      ),
                      const VSpace(4),
                      FlowyText.regular(
                        userProfile.email.isNotEmpty
                            ? userProfile.email
                            : userProfile.name,
                        fontSize: 12,
                        color: theme.colorScheme.onSurface,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    context.push(MobileHomeSettingPage.routeName);
                  },
                  icon: const FlowySvg(
                    FlowySvgs.m_setting_m,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _UserIcon extends StatelessWidget {
  const _UserIcon({
    required this.userIcon,
  });

  final String userIcon;

  @override
  Widget build(BuildContext context) {
    return FlowyButton(
      useIntrinsicWidth: true,
      text: builtInSVGIcons.contains(userIcon)
          // to be compatible with old user icon
          ? FlowySvg(
              FlowySvgData('emoji/$userIcon'),
              size: const Size.square(32),
              blendMode: null,
            )
          : FlowyText(
              userIcon.isNotEmpty ? userIcon : '🐻',
              fontSize: 26,
            ),
      onTap: () async {
        final icon = await context.push<EmojiPickerResult>(
          Uri(
            path: MobileEmojiPickerScreen.routeName,
            queryParameters: {
              MobileEmojiPickerScreen.pageTitle:
                  LocaleKeys.titleBar_userIcon.tr(),
            },
          ).toString(),
        );
        if (icon != null) {
          if (context.mounted) {
            context.read<SettingsUserViewBloc>().add(
                  SettingsUserEvent.updateUserIcon(
                    iconUrl: icon.emoji,
                  ),
                );
          }
        }
      },
    );
  }
}
