import 'package:appflowy/mobile/presentation/home/mobile_folders.dart';
import 'package:appflowy/workspace/application/user/user_workspace_bloc.dart';
import 'package:appflowy/workspace/presentation/home/home_sizes.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MobileHomeSpace extends StatelessWidget {
  const MobileHomeSpace({super.key, required this.userProfile});

  final UserProfilePB userProfile;

  @override
  Widget build(BuildContext context) {
    final workspaceId =
        context.read<UserWorkspaceBloc>().state.currentWorkspace?.workspaceId ??
            '';
    return Scrollbar(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: HomeSpaceViewSizes.mHorizontalPadding,
            vertical: HomeSpaceViewSizes.mVerticalPadding,
          ),
          child: MobileFolders(
            user: userProfile,
            workspaceId: workspaceId,
            showFavorite: false,
          ),
        ),
      ),
    );
  }
}
