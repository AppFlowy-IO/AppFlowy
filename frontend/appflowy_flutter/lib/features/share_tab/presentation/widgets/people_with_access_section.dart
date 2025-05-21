import 'package:appflowy/features/share_tab/data/models/models.dart';
import 'package:appflowy/features/share_tab/presentation/widgets/access_level_list_widget.dart';
import 'package:appflowy/features/share_tab/presentation/widgets/shared_user_widget.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

class PeopleWithAccessSectionCallbacks {
  const PeopleWithAccessSectionCallbacks({
    required this.onRemoveAccess,
    required this.onTurnIntoMember,
    required this.onSelectAccessLevel,
  });

  factory PeopleWithAccessSectionCallbacks.none() {
    return PeopleWithAccessSectionCallbacks(
      onSelectAccessLevel: (_, __) {},
      onTurnIntoMember: (_) {},
      onRemoveAccess: (_) {},
    );
  }

  /// Callback when an access level is selected
  final void Function(SharedUser user, ShareAccessLevel accessLevel)
      onSelectAccessLevel;

  /// Callback when the "Turn into Member" option is selected
  final void Function(SharedUser user) onTurnIntoMember;

  /// Callback when the "Remove access" option is selected
  final void Function(SharedUser user) onRemoveAccess;
}

class PeopleWithAccessSection extends StatelessWidget {
  const PeopleWithAccessSection({
    super.key,
    required this.currentUserEmail,
    required this.users,
    this.callbacks,
  });

  final String currentUserEmail;
  final List<SharedUser> users;
  final PeopleWithAccessSectionCallbacks? callbacks;

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    final currentUser = users.firstWhereOrNull(
      (user) => user.email == currentUserEmail,
    );

    return AFMenuSection(
      title: 'People with access',
      constraints: BoxConstraints(
        maxHeight: 240,
      ),
      padding: EdgeInsets.symmetric(
        vertical: theme.spacing.xs,
      ),
      children: users.map((user) {
        if (currentUser == null) {
          return const SizedBox.shrink();
        }

        return SharedUserWidget(
          user: user,
          currentUser: currentUser,
          callbacks: AccessLevelListCallbacks(
            onRemoveAccess: () => callbacks?.onRemoveAccess.call(user),
            onTurnIntoMember: () => callbacks?.onTurnIntoMember.call(user),
            onSelectAccessLevel: (accessLevel) =>
                callbacks?.onSelectAccessLevel.call(user, accessLevel),
          ),
        );
      }).toList(),
    );
  }
}
