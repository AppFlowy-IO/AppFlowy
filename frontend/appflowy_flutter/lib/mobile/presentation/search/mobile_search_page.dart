import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/auth/auth_service.dart';
import 'package:appflowy/workspace/application/command_palette/command_palette_bloc.dart';
import 'package:appflowy/workspace/presentation/home/errors/workspace_failed_screen.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/workspace.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/auth.pbenum.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'mobile_search_ask_ai_entrance.dart';
import 'mobile_search_result.dart';
import 'mobile_search_textfield.dart';

class MobileSearchScreen extends StatelessWidget {
  const MobileSearchScreen({
    super.key,
  });

  static const routeName = '/search';

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Future.wait([
        FolderEventGetCurrentWorkspaceSetting().send(),
        getIt<AuthService>().getUser(),
      ]),
      builder: (context, snapshots) {
        if (!snapshots.hasData) {
          return const Center(child: CircularProgressIndicator.adaptive());
        }

        final workspaceSetting = snapshots.data?[0].fold(
          (workspaceSettingPB) {
            return workspaceSettingPB as WorkspaceSettingPB?;
          },
          (error) => null,
        );
        final userProfile = snapshots.data?[1].fold(
          (userProfilePB) {
            return userProfilePB as UserProfilePB?;
          },
          (error) => null,
        );

        // In the unlikely case either of the above is null, eg.
        // when a workspace is already open this can happen.
        if (workspaceSetting == null || userProfile == null) {
          return const WorkspaceFailedScreen();
        }

        Sentry.configureScope(
          (scope) => scope.setUser(
            SentryUser(
              id: userProfile.id.toString(),
            ),
          ),
        );
        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: Provider.value(
              value: userProfile,
              child: MobileSearchPage(
                userProfile: userProfile,
                workspaceSetting: workspaceSetting,
              ),
            ),
          ),
        );
      },
    );
  }
}

class MobileSearchPage extends StatelessWidget {
  const MobileSearchPage({
    super.key,
    required this.userProfile,
    required this.workspaceSetting,
  });

  final UserProfilePB userProfile;
  final WorkspaceSettingPB workspaceSetting;

  bool get enableShowAISearch =>
      userProfile.authenticator == AuthenticatorPB.AppFlowyCloud;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CommandPaletteBloc, CommandPaletteState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MobileSearchTextfield(
                hintText: enableShowAISearch
                    ? LocaleKeys.search_searchOrAskAI.tr()
                    : LocaleKeys.search_label.tr(),
                query: state.query ?? '',
                onChanged: (value) => context
                    .read<CommandPaletteBloc>()
                    .add(CommandPaletteEvent.searchChanged(search: value)),
              ),
              if (enableShowAISearch) MobileSearchAskAiEntrance(),
              Flexible(child: MobileSearchResult()),
            ],
          ),
        );
      },
    );
  }
}
