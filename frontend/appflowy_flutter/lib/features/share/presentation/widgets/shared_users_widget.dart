import 'package:appflowy/features/share/logic/share_with_user_bloc.dart';
import 'package:appflowy/features/share/presentation/widgets/shared_user_widget.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Example usage in a list with BlocBuilder
class SharedUserList extends StatelessWidget {
  const SharedUserList({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ShareWithUserBloc, ShareWithUserState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.errorMessage.isNotEmpty) {
          return Center(child: Text(state.errorMessage));
        }
        final users = state.users;
        // Assume current user is the first in the list for demo; adjust as needed
        final currentUserEmail = users.isNotEmpty ? users.first.email : '';
        return ListView.separated(
          shrinkWrap: true,
          itemCount: users.length,
          separatorBuilder: (_, __) => AFDivider(),
          itemBuilder: (context, index) {
            final user = users[index];
            final isCurrentUser = user.email == currentUserEmail;
            return SharedUserWidget(
              user: user,
              isCurrentUser: isCurrentUser,
              onEdit: isCurrentUser
                  ? null
                  : () {
                      // Show edit dialog or menu
                      // context.read<ShareWithUserBloc>().add(...)
                    },
            );
          },
        );
      },
    );
  }
}
