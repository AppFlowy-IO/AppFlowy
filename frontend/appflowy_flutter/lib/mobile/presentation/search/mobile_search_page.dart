import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/auth/auth_service.dart';
import 'package:appflowy/workspace/application/command_palette/command_palette_bloc.dart';
import 'package:appflowy/workspace/presentation/home/errors/workspace_failed_screen.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/workspace.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

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

        final latest = snapshots.data?[0].fold(
          (latest) {
            return latest as WorkspaceLatestPB?;
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
        if (latest == null || userProfile == null) {
          return const WorkspaceFailedScreen();
        }

        return Provider.value(
          value: userProfile,
          child: MobileSearchPage(
            userProfile: userProfile,
            workspaceLatestPB: latest,
          ),
        );
      },
    );
  }
}

class MobileSearchPage extends StatefulWidget {
  const MobileSearchPage({
    super.key,
    required this.userProfile,
    required this.workspaceLatestPB,
  });

  final UserProfilePB userProfile;
  final WorkspaceLatestPB workspaceLatestPB;

  @override
  State<MobileSearchPage> createState() => _MobileSearchPageState();
}

class _MobileSearchPageState extends State<MobileSearchPage> {
  bool get enableShowAISearch =>
      widget.userProfile.workspaceType == WorkspaceTypePB.ServerW;

  final focusNode = FocusNode();

  @override
  void dispose() {
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CommandPaletteBloc, CommandPaletteState>(
      builder: (context, state) {
        return SafeArea(
          child: Scaffold(
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MobileSearchTextfield(
                    focusNode: focusNode,
                    hintText: enableShowAISearch
                        ? LocaleKeys.search_searchOrAskAI.tr()
                        : LocaleKeys.search_label.tr(),
                    query: state.query ?? '',
                    onChanged: (value) =>
                        context.read<CommandPaletteBloc>().add(
                              CommandPaletteEvent.searchChanged(search: value),
                            ),
                  ),
                  if (enableShowAISearch)
                    MobileSearchAskAiEntrance(query: state.query),
                  Flexible(
                    child: NotificationListener(
                      child: MobileSearchResult(),
                      onNotification: (t) {
                        if (t is ScrollUpdateNotification) {
                          if (focusNode.hasFocus) {
                            focusNode.unfocus();
                          }
                        }
                        return true;
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
