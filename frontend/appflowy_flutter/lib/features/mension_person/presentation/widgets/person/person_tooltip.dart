import 'package:appflowy/features/mension_person/data/models/person.dart';
import 'package:appflowy/features/mension_person/presentation/mention_menu_service.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PersonToolTip extends StatefulWidget {
  const PersonToolTip({
    super.key,
    required this.child,
    required this.person,
    required this.isMyself,
  });

  final Widget child;
  final Person person;
  final bool isMyself;

  @override
  State<PersonToolTip> createState() => _PersonToolTipState();
}

class _PersonToolTipState extends State<PersonToolTip> {
  final popoverController = PopoverController();
  final globalKey = GlobalKey();
  OverlayEntry? overlayEntry;

  Person get person => widget.person;
  String get email => person.email;
  String get name => person.name;
  bool get isMyself => widget.isMyself;

  @override
  void dispose() {
    hide();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      key: globalKey,
      onEnter: (e) {
        show();
      },
      onExit: (e) {
        hide();
      },
      child: widget.child,
    );
  }

  Widget buildTooltip(BuildContext context) {
    final theme = AppFlowyTheme.of(context), spacing = theme.spacing;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: 320,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.surfaceColorScheme.inverse,
          borderRadius: BorderRadius.circular(spacing.m),
        ),
        child: Padding(
          padding:
              EdgeInsets.symmetric(horizontal: spacing.m, vertical: spacing.l),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isMyself
                    ? LocaleKeys.document_mentionMenu_you.tr()
                    : LocaleKeys.document_mentionMenu_personItemTooltip
                        .tr(args: [name]),
                style: theme.textStyle.body
                    .enhanced(color: theme.textColorScheme.onFill),
              ),
              Text(
                email,
                style: theme.textStyle.body
                    .standard(color: theme.textColorScheme.secondary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void show() {
    final renderbox =
        globalKey.currentContext?.findRenderObject() as RenderBox?;
    final mentionInfo = context.read<MentionMenuServiceInfo>(),
        editorState = mentionInfo.editorState,
        editorRenderBox = editorState.renderBox;
    if (renderbox == null || editorRenderBox == null) return;

    final editorOffset = editorRenderBox.localToGlobal(Offset.zero),
        editorSize = editorRenderBox.size,
        widgetOffset = renderbox.localToGlobal(Offset.zero),
        widgetSize = renderbox.size,
        tooltipWidth = 320,
        horizontalPadding = 2;
    final overRight = widgetOffset.dx + widgetSize.width + tooltipWidth >
            editorOffset.dx + editorSize.width,
        overLeft = widgetOffset.dx - tooltipWidth < editorOffset.dx;
    double left = widgetOffset.dx + widgetSize.width + horizontalPadding,
        top = widgetOffset.dy;
    if (overRight && overLeft) {
      left = editorOffset.dx + editorSize.width - tooltipWidth;
    } else if (overRight) {
      left = widgetOffset.dx - tooltipWidth - horizontalPadding;
    }

    overlayEntry?.remove();
    overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(left: left, top: top, child: buildTooltip(context));
      },
    );
    Overlay.of(context).insert(overlayEntry!);
  }

  void hide() {
    overlayEntry?.remove();
    overlayEntry = null;
  }
}
