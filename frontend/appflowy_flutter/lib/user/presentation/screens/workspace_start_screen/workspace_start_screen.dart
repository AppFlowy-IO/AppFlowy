import 'dart:io';

import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/presentation/screens/workspace_start_screen/desktop_workspace_start_screen.dart';
import 'package:appflowy/user/presentation/screens/workspace_start_screen/mobile_workspace_start_screen.dart';
import 'package:appflowy/workspace/application/workspace/workspace_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class WorkspaceStartScreen extends StatelessWidget {
  final UserProfilePB userProfile;
  static const routeName = "/WorkspaceStartScreen";
  const WorkspaceStartScreen({
    Key? key,
    required this.userProfile,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<WorkspaceBloc>(param1: userProfile)
        ..add(const WorkspaceEvent.initial()),
      child: BlocBuilder<WorkspaceBloc, WorkspaceState>(
        builder: (context, state) {
          if (Platform.isAndroid || Platform.isIOS) {
            return MobileWorkspaceStartScreen(
              workspaceState: state,
            );
          }
          return DesktopWorkspaceStartScreen(
            workspaceState: state,
          );
        },
      ),
    );
  }
}
