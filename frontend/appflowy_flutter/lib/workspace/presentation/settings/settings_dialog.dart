import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/settings_appearance_view.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/settings_file_system_view.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/settings_language_view.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/settings_user_view.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/settings_menu.dart';
import 'package:appflowy/workspace/application/settings/settings_dialog_bloc.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

const _dialogHorizontalPadding = EdgeInsets.symmetric(horizontal: 12);
const _contentInsetPadding = EdgeInsets.fromLTRB(0.0, 12.0, 0.0, 16.0);

class SettingsDialog extends StatelessWidget {
  final UserProfilePB user;
  SettingsDialog(this.user, {Key? key}) : super(key: ValueKey(user.id));

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SettingsDialogBloc>(
      create: (context) => getIt<SettingsDialogBloc>(param1: user)
        ..add(const SettingsDialogEvent.initial()),
      child: BlocBuilder<SettingsDialogBloc, SettingsDialogState>(
        builder: (context, state) => FlowyDialog(
          title: Padding(
            padding: _dialogHorizontalPadding + _contentInsetPadding,
            child: FlowyText(
              LocaleKeys.settings_title.tr(),
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.tertiary,
            ),
          ),
          child: ScaffoldMessenger(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: Padding(
                padding: _dialogHorizontalPadding,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 200,
                      child: SettingsMenu(
                        changeSelectedPage: (index) {
                          context
                              .read<SettingsDialogBloc>()
                              .add(SettingsDialogEvent.setSelectedPage(index));
                        },
                        currentPage:
                            context.read<SettingsDialogBloc>().state.page,
                      ),
                    ),
                    VerticalDivider(
                      color: Theme.of(context).dividerColor,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: getSettingsView(
                        context.read<SettingsDialogBloc>().state.page,
                        context.read<SettingsDialogBloc>().state.userProfile,
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget getSettingsView(SettingsPage page, UserProfilePB user) {
    switch (page) {
      case SettingsPage.appearance:
        return const SettingsAppearanceView();
      case SettingsPage.language:
        return const SettingsLanguageView();
      case SettingsPage.files:
        return const SettingsFileSystemView();
      case SettingsPage.user:
        return SettingsUserView(user);
      default:
        return Container();
    }
  }
}
