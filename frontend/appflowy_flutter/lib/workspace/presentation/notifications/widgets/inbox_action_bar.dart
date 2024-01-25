import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/user/application/notification_filter/notification_filter_bloc.dart';
import 'package:appflowy/user/application/reminder/reminder_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class InboxActionBar extends StatelessWidget {
  const InboxActionBar({
    super.key,
    required this.hasUnreads,
    required this.showUnreadsOnly,
  });

  final bool hasUnreads;
  final bool showUnreadsOnly;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AFThemeExtension.of(context).calloutBGColor,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _MarkAsReadButton(
              onMarkAllRead: !hasUnreads
                  ? null
                  : () => context
                      .read<ReminderBloc>()
                      .add(const ReminderEvent.markAllRead()),
            ),
            _ToggleUnreadsButton(
              showUnreadsOnly: showUnreadsOnly,
              onToggled: (_) => context
                  .read<NotificationFilterBloc>()
                  .add(const NotificationFilterEvent.toggleShowUnreadsOnly()),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleUnreadsButton extends StatefulWidget {
  const _ToggleUnreadsButton({
    required this.onToggled,
    this.showUnreadsOnly = false,
  });

  final Function(bool) onToggled;
  final bool showUnreadsOnly;

  @override
  State<_ToggleUnreadsButton> createState() => _ToggleUnreadsButtonState();
}

class _ToggleUnreadsButtonState extends State<_ToggleUnreadsButton> {
  late bool showUnreadsOnly = widget.showUnreadsOnly;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<bool>(
      onSelectionChanged: (Set<bool> newSelection) {
        setState(() => showUnreadsOnly = newSelection.first);
        widget.onToggled(showUnreadsOnly);
      },
      showSelectedIcon: false,
      style: ButtonStyle(
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        side: MaterialStatePropertyAll(
          BorderSide(color: Theme.of(context).dividerColor),
        ),
        shape: const MaterialStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: Corners.s6Border,
          ),
        ),
        foregroundColor: MaterialStateProperty.resolveWith<Color>(
          (state) {
            if (state.contains(MaterialState.selected)) {
              return Theme.of(context).colorScheme.onPrimary;
            }

            return AFThemeExtension.of(context).textColor;
          },
        ),
        backgroundColor: MaterialStateProperty.resolveWith<Color>(
          (state) {
            if (state.contains(MaterialState.selected)) {
              return Theme.of(context).colorScheme.primary;
            }

            if (state.contains(MaterialState.hovered)) {
              return AFThemeExtension.of(context).lightGreyHover;
            }

            return Theme.of(context).cardColor;
          },
        ),
      ),
      segments: [
        ButtonSegment<bool>(
          value: false,
          label: Text(
            LocaleKeys.notificationHub_actions_showAll.tr(),
            style: const TextStyle(fontSize: 12),
          ),
        ),
        ButtonSegment<bool>(
          value: true,
          label: Text(
            LocaleKeys.notificationHub_actions_showUnreads.tr(),
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
      selected: <bool>{showUnreadsOnly},
    );
  }
}

class _MarkAsReadButton extends StatefulWidget {
  const _MarkAsReadButton({this.onMarkAllRead});

  final VoidCallback? onMarkAllRead;

  @override
  State<_MarkAsReadButton> createState() => _MarkAsReadButtonState();
}

class _MarkAsReadButtonState extends State<_MarkAsReadButton> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: widget.onMarkAllRead != null ? 1 : 0.5,
      child: FlowyHover(
        onHover: (isHovering) => setState(() => _isHovering = isHovering),
        resetHoverOnRebuild: false,
        child: FlowyTextButton(
          LocaleKeys.notificationHub_actions_markAllRead.tr(),
          fontColor: widget.onMarkAllRead != null && _isHovering
              ? Theme.of(context).colorScheme.onSurface
              : AFThemeExtension.of(context).textColor,
          heading: FlowySvg(
            FlowySvgs.checklist_s,
            color: widget.onMarkAllRead != null && _isHovering
                ? Theme.of(context).colorScheme.onSurface
                : AFThemeExtension.of(context).textColor,
          ),
          hoverColor: widget.onMarkAllRead != null && _isHovering
              ? Theme.of(context).colorScheme.primary
              : null,
          onPressed: widget.onMarkAllRead,
        ),
      ),
    );
  }
}
