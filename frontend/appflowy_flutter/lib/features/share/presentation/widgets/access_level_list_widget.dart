import 'package:appflowy/features/share/data/models/models.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flutter/material.dart';

/// A widget that displays a list of access levels for sharing.
///
/// This widget is used in a popover to allow users to select different access levels
/// for shared content, as well as options to turn users into members or remove access.
class AccessLevelListWidget extends StatelessWidget {
  const AccessLevelListWidget({
    super.key,
    required this.selectedAccessLevel,
    required this.onSelect,
    required this.onTurnIntoMember,
    required this.onRemoveAccess,
  });

  /// The currently selected access level
  final ShareAccessLevel selectedAccessLevel;

  /// Callback when an access level is selected
  final void Function(ShareAccessLevel) onSelect;

  /// Callback when the "Turn into Member" option is selected
  final VoidCallback onTurnIntoMember;

  /// Callback when the "Remove access" option is selected
  final VoidCallback onRemoveAccess;

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    return AFMenu(
      width: 240,
      children: [
        // Display all available access level options
        _buildAccessLevelItem(
          context,
          accessLevel: ShareAccessLevel.fullAccess,
          onTap: () => onSelect(ShareAccessLevel.fullAccess),
        ),
        _buildAccessLevelItem(
          context,
          accessLevel: ShareAccessLevel.readAndWrite,
          onTap: () => onSelect(ShareAccessLevel.readAndWrite),
        ),
        _buildAccessLevelItem(
          context,
          accessLevel: ShareAccessLevel.readAndComment,
          onTap: () => onSelect(ShareAccessLevel.readAndComment),
        ),
        _buildAccessLevelItem(
          context,
          accessLevel: ShareAccessLevel.readOnly,
          onTap: () => onSelect(ShareAccessLevel.readOnly),
        ),

        AFDivider(spacing: theme.spacing.m),
        // Additional user management options
        AFTextMenuItem(
          title: 'Turn into Member',
          onTap: onTurnIntoMember,
        ),
        AFTextMenuItem(
          title: 'Remove access',
          onTap: onRemoveAccess,
          titleColor: theme.textColorScheme.error,
        ),
      ],
    );
  }

  /// Builds an individual access level menu item
  ///
  /// @param context The build context
  /// @param accessLevel The access level to display
  /// @param onTap Callback when this item is tapped
  /// @return A menu item widget for the specified access level
  Widget _buildAccessLevelItem(
    BuildContext context, {
    required ShareAccessLevel accessLevel,
    required VoidCallback onTap,
  }) {
    return AFTextMenuItem(
      title: accessLevel.i18n,
      showSelectedBackground: false,
      selected: selectedAccessLevel == accessLevel,
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
