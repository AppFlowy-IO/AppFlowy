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

/// A widget that displays a list of access levels for sharing.
///
/// This widget is used in a popover to allow users to select different access levels
/// for shared content, as well as options to turn users into members or remove access.
class AccessLevelListWidget extends StatelessWidget {
  const AccessLevelListWidget({
    super.key,
    this.enableAccessLevelSelection = true,
    required this.selectedAccessLevel,
    required this.callbacks,
  });

  /// Enable access level selection
  final bool enableAccessLevelSelection;

  /// The currently selected access level
  final ShareAccessLevel selectedAccessLevel;

  /// Callbacks
  final AccessLevelListCallbacks callbacks;

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    return AFMenu(
      width: enableAccessLevelSelection ? 240 : 160,
      children: [
        // Display all available access level options
        if (enableAccessLevelSelection) ...[
          _buildAccessLevelItem(
            context,
            accessLevel: ShareAccessLevel.fullAccess,
            onTap: () =>
                callbacks.onSelectAccessLevel(ShareAccessLevel.fullAccess),
          ),
          _buildAccessLevelItem(
            context,
            accessLevel: ShareAccessLevel.readAndWrite,
            onTap: () =>
                callbacks.onSelectAccessLevel(ShareAccessLevel.readAndWrite),
          ),
          _buildAccessLevelItem(
            context,
            accessLevel: ShareAccessLevel.readAndComment,
            onTap: () =>
                callbacks.onSelectAccessLevel(ShareAccessLevel.readAndComment),
          ),
          _buildAccessLevelItem(
            context,
            accessLevel: ShareAccessLevel.readOnly,
            onTap: () =>
                callbacks.onSelectAccessLevel(ShareAccessLevel.readOnly),
          ),
          AFDivider(spacing: theme.spacing.m),
        ],

        // Additional user management options
        AFTextMenuItem(
          title: LocaleKeys.shareTab_turnIntoMember.tr(),
          onTap: callbacks.onTurnIntoMember,
        ),
        AFTextMenuItem(
          title: LocaleKeys.shareTab_removeAccess.tr(),
          titleColor: theme.textColorScheme.error,
          onTap: callbacks.onRemoveAccess,
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
