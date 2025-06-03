import 'package:appflowy/features/share_tab/data/models/models.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class AccessLevelListCallbacks {
  const AccessLevelListCallbacks({
    required this.onSelectAccessLevel,
    required this.onTurnIntoMember,
    required this.onRemoveAccess,
  });

  factory AccessLevelListCallbacks.none() {
    return AccessLevelListCallbacks(
      onSelectAccessLevel: (_) {},
      onTurnIntoMember: () {},
      onRemoveAccess: () {},
    );
  }

  /// Callback when an access level is selected
  final void Function(ShareAccessLevel accessLevel) onSelectAccessLevel;

  /// Callback when the "Turn into Member" option is selected
  final VoidCallback onTurnIntoMember;

  /// Callback when the "Remove access" option is selected
  final VoidCallback onRemoveAccess;

  /// Copy
  AccessLevelListCallbacks copyWith({
    VoidCallback? onRemoveAccess,
    VoidCallback? onTurnIntoMember,
    void Function(ShareAccessLevel accessLevel)? onSelectAccessLevel,
  }) {
    return AccessLevelListCallbacks(
      onRemoveAccess: onRemoveAccess ?? this.onRemoveAccess,
      onTurnIntoMember: onTurnIntoMember ?? this.onTurnIntoMember,
      onSelectAccessLevel: onSelectAccessLevel ?? this.onSelectAccessLevel,
    );
  }
}

enum AdditionalUserManagementOptions {
  turnIntoMember,
  removeAccess,
}

/// A widget that displays a list of access levels for sharing.
///
/// This widget is used in a popover to allow users to select different access levels
/// for shared content, as well as options to turn users into members or remove access.
class AccessLevelListWidget extends StatelessWidget {
  const AccessLevelListWidget({
    super.key,
    required this.selectedAccessLevel,
    required this.callbacks,
    required this.supportedAccessLevels,
    required this.additionalUserManagementOptions,
  });

  /// The currently selected access level
  final ShareAccessLevel selectedAccessLevel;

  /// Callbacks
  final AccessLevelListCallbacks callbacks;

  /// Supported access levels
  final List<ShareAccessLevel> supportedAccessLevels;

  /// Additional user management options
  final List<AdditionalUserManagementOptions> additionalUserManagementOptions;

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    return AFMenu(
      width: supportedAccessLevels.isNotEmpty ? 260 : 160,
      children: [
        // Display all available access level options
        if (supportedAccessLevels.isNotEmpty) ...[
          ...supportedAccessLevels.map(
            (accessLevel) => _buildAccessLevelItem(
              context,
              accessLevel: accessLevel,
              onTap: () => callbacks.onSelectAccessLevel(accessLevel),
            ),
          ),
          AFDivider(spacing: theme.spacing.m),
        ],

        // Additional user management options
        if (additionalUserManagementOptions
            .contains(AdditionalUserManagementOptions.turnIntoMember))
          AFTextMenuItem(
            title: LocaleKeys.shareTab_turnIntoMember.tr(),
            onTap: callbacks.onTurnIntoMember,
          ),
        if (additionalUserManagementOptions
            .contains(AdditionalUserManagementOptions.removeAccess))
          AFTextMenuItem(
            title: LocaleKeys.shareTab_removeAccess.tr(),
            titleColor: theme.textColorScheme.error,
            onTap: callbacks.onRemoveAccess,
          ),
      ],
    );
  }

  Widget _buildAccessLevelItem(
    BuildContext context, {
    required ShareAccessLevel accessLevel,
    required VoidCallback onTap,
  }) {
    return AFTextMenuItem(
      title: accessLevel.title,
      subtitle: accessLevel.subtitle,

      showSelectedBackground: false,
      selected: selectedAccessLevel == accessLevel,
      leading: FlowySvg(
        accessLevel.icon,
      ),
      // Show a checkmark icon for the currently selected access level
      trailing: selectedAccessLevel == accessLevel
          ? FlowySvg(
              FlowySvgs.m_blue_check_s,
              blendMode: null,
            )
          : null,
      onTap: onTap,
    );
  }
}
