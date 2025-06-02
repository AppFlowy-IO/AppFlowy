import 'package:appflowy/features/workspace/logic/workspace_bloc.dart';
import 'package:appflowy/workspace/application/sidebar/space/space_bloc.dart';
import 'package:appflowy/workspace/application/user/prelude.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/single_child_widget.dart';

class ViewSelector extends StatelessWidget {
  const ViewSelector({
    super.key,
    required this.viewSelectorCubit,
    required this.child,
  });

  final SingleChildWidget viewSelectorCubit;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final userWorkspaceBloc = context.read<UserWorkspaceBloc>();
    final userProfile = userWorkspaceBloc.state.userProfile;
    final workspaceId =
        userWorkspaceBloc.state.currentWorkspace?.workspaceId ?? '';

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) {
            return SpaceBloc(
              userProfile: userProfile,
              workspaceId: workspaceId,
            )..add(const SpaceEvent.initial(openFirstPage: false));
          },
        ),
        viewSelectorCubit,
      ],
      child: child,
    );
  }
}
