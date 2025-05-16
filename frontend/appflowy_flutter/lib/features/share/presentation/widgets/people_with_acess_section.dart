import 'package:appflowy/features/share/data/models/shared_user.dart';
import 'package:appflowy/features/share/presentation/widgets/shared_user_widget.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flutter/material.dart';

class PeopleWithAccessSection extends StatelessWidget {
  const PeopleWithAccessSection({
    super.key,
    required this.currentUserEmail,
    required this.users,
  });

  final String currentUserEmail;
  final List<SharedUser> users;

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    return AFMenuSection(
      title: 'People with access',
      padding: EdgeInsets.symmetric(
        vertical: theme.spacing.s,
      ),
      children: users.map((user) {
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
      }).toList(),
    );
  }
}
