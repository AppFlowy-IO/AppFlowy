import 'package:appflowy/features/share/data/models/models.dart';
import 'package:appflowy/features/share/presentation/widgets/access_level_list_widget.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';

class EditAccessLevelWidget extends StatefulWidget {
  const EditAccessLevelWidget({
    super.key,
    required this.onTap,
    required this.selectedAccessLevel,
    this.disabled = false,
  });

  final VoidCallback onTap;
  final ShareAccessLevel selectedAccessLevel;
  final bool disabled;

  @override
  State<EditAccessLevelWidget> createState() => _EditAccessLevelWidgetState();
}

class _EditAccessLevelWidgetState extends State<EditAccessLevelWidget> {
  final popoverController = AFPopoverController();

  @override
  void dispose() {
    popoverController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);

    return AFPopover(
      padding: EdgeInsets.zero,
      decoration: BoxDecoration(), // the access level widget has a border
      controller: popoverController,
      popover: (_) {
        return AccessLevelListWidget(
          selectedAccessLevel: widget.selectedAccessLevel,
          onSelect: (accessLevel) {
            widget.onTap();
          },
          onTurnIntoMember: () {},
          onRemoveAccess: () {},
        );
      },
      child: AFGhostButton.normal(
        disabled: widget.disabled,
        onTap: () {
          popoverController.show();
        },
        padding: EdgeInsets.symmetric(
          vertical: theme.spacing.s,
          horizontal: theme.spacing.l,
        ),
        builder: (context, isHovering, disabled) {
          return Row(
            children: [
              Text(
                widget.selectedAccessLevel.i18n,
                style: theme.textStyle.body.standard(
                  color: disabled
                      ? theme.textColorScheme.secondary
                      : theme.textColorScheme.primary,
                ),
              ),
              HSpace(theme.spacing.xs),
              FlowySvg(
                FlowySvgs.arrow_down_s,
                color: theme.textColorScheme.secondary,
              ),
            ],
          );
        },
      ),
    );
  }
}
