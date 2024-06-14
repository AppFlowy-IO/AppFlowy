import 'package:appflowy/mobile/presentation/home/mobile_folders.dart';
import 'package:appflowy/workspace/application/user/user_workspace_bloc.dart';
import 'package:appflowy/workspace/presentation/home/home_sizes.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MobileHomeSpace extends StatefulWidget {
  const MobileHomeSpace({super.key, required this.userProfile});

  final UserProfilePB userProfile;

  @override
  State<MobileHomeSpace> createState() => _MobileHomeSpaceState();
}

class _MobileHomeSpaceState extends State<MobileHomeSpace>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final workspaceId =
        context.read<UserWorkspaceBloc>().state.currentWorkspace?.workspaceId ??
            '';
    return Scrollbar(
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            left: HomeSpaceViewSizes.mHorizontalPadding,
            right: HomeSpaceViewSizes.mHorizontalPadding,
            top: HomeSpaceViewSizes.mVerticalPadding,
            bottom: HomeSpaceViewSizes.mVerticalPadding +
                MediaQuery.of(context).padding.bottom,
          ),
          child: MobileFolders(
            user: widget.userProfile,
            workspaceId: workspaceId,
            showFavorite: false,
          ),
        ),
      ),
    );
  }
}
