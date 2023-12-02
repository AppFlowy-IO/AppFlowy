import 'package:appflowy/mobile/application/user_profile/user_profile_bloc.dart';
import 'package:appflowy/mobile/presentation/home/mobile_home_page_header.dart';
import 'package:appflowy/workspace/presentation/home/errors/workspace_failed_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MobileNotificationsScreen extends StatelessWidget {
  const MobileNotificationsScreen({super.key});

  static const routeName = '/notifications';

  @override
  Widget build(BuildContext context) {
    return BlocProvider<UserProfileBloc>(
      create: (context) =>
          UserProfileBloc()..add(const UserProfileEvent.started()),
      child: BlocBuilder<UserProfileBloc, UserProfileState>(
        builder: (context, state) => state.maybeWhen(
          orElse: () => const Center(
            child: CircularProgressIndicator.adaptive(),
          ),
          workspaceFailure: () => const WorkspaceFailedScreen(),
          success: (workspaceSetting, userProfile) {
            return Scaffold(
              body: SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: MobileHomePageHeader(userProfile: userProfile),
                    ),
                    const Divider(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
