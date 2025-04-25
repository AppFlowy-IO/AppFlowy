import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/application/notification/notification_reminder_bloc.dart';
import 'package:appflowy/mobile/application/page_style/document_page_style_bloc.dart';
import 'package:appflowy/mobile/presentation/notifications/widgets/color.dart';
import 'package:appflowy/plugins/document/presentation/editor_configuration.dart';
import 'package:appflowy/plugins/document/presentation/editor_style.dart';
import 'package:appflowy/user/application/reminder/reminder_extension.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

const _kNotificationIconHeight = 36.0;

class NotificationIcon extends StatelessWidget {
  const NotificationIcon({
    super.key,
    required this.reminder,
  });

  final ReminderPB reminder;

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    return SizedBox(
      width: 42,
      height: 36,
      child: Stack(
        children: [
          const FlowySvg(
            FlowySvgs.m_notification_reminder_s,
            size: Size.square(32),
            blendMode: null,
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.fillColorScheme.primary,
              ),
              child: Center(
                child: Text(
                  '@',
                  style: TextStyle(
                    color: theme.iconColorScheme.primary,
                    fontSize: 12,
                    height: 1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class NotificationCheckIcon extends StatelessWidget {
  const NotificationCheckIcon({super.key, required this.isSelected});

  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _kNotificationIconHeight,
      child: Center(
        child: FlowySvg(
          isSelected
              ? FlowySvgs.m_notification_multi_select_s
              : FlowySvgs.m_notification_multi_unselect_s,
          blendMode: isSelected ? null : BlendMode.srcIn,
        ),
      ),
    );
  }
}

class UnreadRedDot extends StatelessWidget {
  const UnreadRedDot({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    return SizedBox(
      height: _kNotificationIconHeight,
      child: Center(
        child: SizedBox.square(
          dimension: 7.0,
          child: DecoratedBox(
            decoration: ShapeDecoration(
              color: theme.borderColorScheme.errorThick,
              shape: OvalBorder(),
            ),
          ),
        ),
      ),
    );
  }
}

class NotificationContent extends StatefulWidget {
  const NotificationContent({
    super.key,
    required this.reminder,
  });

  final ReminderPB reminder;

  @override
  State<NotificationContent> createState() => _NotificationContentState();
}

class _NotificationContentState extends State<NotificationContent> {
  AppFlowyThemeData get theme => AppFlowyTheme.of(context);

  @override
  void didUpdateWidget(covariant NotificationContent oldWidget) {
    super.didUpdateWidget(oldWidget);

    context.read<NotificationReminderBloc>().add(
          const NotificationReminderEvent.reset(),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationReminderBloc, NotificationReminderState>(
      builder: (context, state) {
        final view = state.view;
        if (view == null) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // title & time
            _buildHeader(state.createdAt, !widget.reminder.isRead),
            // page name
            _buildPageName(context, state.isLocked, state.pageTitle),
            // content
            _buildContent(view, nodes: state.nodes),
          ],
        );
      },
    );
  }

  Widget _buildContent(ViewPB view, {List<Node>? nodes}) {
    if (view.layout.isDocumentView && nodes != null) {
      return IntrinsicHeight(
        child: BlocProvider(
          create: (context) => DocumentPageStyleBloc(view: view),
          child: NotificationDocumentContent(
            reminder: widget.reminder,
            nodes: nodes,
          ),
        ),
      );
    } else if (view.layout.isDatabaseView) {
      final opacity = widget.reminder.type == ReminderType.past ? 0.3 : 1.0;
      return Opacity(
        opacity: opacity,
        child: FlowyText(
          widget.reminder.message,
          fontSize: 14,
          figmaLineHeight: 22,
          color: context.notificationItemTextColor,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildHeader(String createAt, bool unread) {
    return SizedBox(
      height: 22,
      child: Row(
        children: [
          FlowyText.semibold(
            LocaleKeys.settings_notifications_titles_reminder.tr(),
            fontSize: 14,
            figmaLineHeight: 20,
            color: theme.textColorScheme.primary,
          ),
          Spacer(),
          if (createAt.isNotEmpty)
            FlowyText.regular(
              createAt,
              fontSize: 12,
              figmaLineHeight: 18,
              color: theme.textColorScheme.secondary,
            ),
          if (unread) ...[
            HSpace(4),
            const UnreadRedDot(),
          ],
        ],
      ),
    );
  }

  Widget _buildPageName(
    BuildContext context,
    bool isLocked,
    String pageTitle,
  ) {
    return Opacity(
      opacity: 0.5,
      child: SizedBox(
        height: 18,
        child: Row(
          children: [
            /// TODO: need to be replaced after reminder support more types
            FlowyText.regular(
              LocaleKeys.notificationHub_mentionedYou.tr(),
              fontSize: 12,
              figmaLineHeight: 18,
              color: theme.textColorScheme.secondary,
            ),
            const NotificationEllipse(),
            if (isLocked)
              Padding(
                padding: EdgeInsets.only(right: 5),
                child: FlowySvg(
                  FlowySvgs.notification_lock_s,
                  color: theme.iconColorScheme.secondary,
                ),
              ),
            Flexible(
              child: FlowyText.regular(
                pageTitle,
                fontSize: 12,
                figmaLineHeight: 18,
                color: theme.textColorScheme.secondary,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NotificationEllipse extends StatelessWidget {
  const NotificationEllipse({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 2.50,
      height: 2.50,
      margin: const EdgeInsets.symmetric(horizontal: 6.0),
      decoration: ShapeDecoration(
        color: context.notificationItemTextColor,
        shape: const OvalBorder(),
      ),
    );
  }
}

class NotificationDocumentContent extends StatelessWidget {
  const NotificationDocumentContent({
    super.key,
    required this.reminder,
    required this.nodes,
  });

  final ReminderPB reminder;
  final List<Node> nodes;

  @override
  Widget build(BuildContext context) {
    final editorState = EditorState(
      document: Document(
        root: pageNode(children: nodes),
      ),
    );

    final styleCustomizer = EditorStyleCustomizer(
      context: context,
      padding: EdgeInsets.zero,
    );

    final editorStyle = styleCustomizer.style().copyWith(
          // hide the cursor
          cursorColor: Colors.transparent,
          cursorWidth: 0,
          textStyleConfiguration: TextStyleConfiguration(
            lineHeight: 22 / 14,
            applyHeightToFirstAscent: true,
            applyHeightToLastDescent: true,
            text: TextStyle(
              fontSize: 14,
              color: context.notificationItemTextColor,
              height: 22 / 14,
              fontWeight: FontWeight.w400,
              leadingDistribution: TextLeadingDistribution.even,
            ),
          ),
        );

    final blockBuilders = buildBlockComponentBuilders(
      context: context,
      editorState: editorState,
      styleCustomizer: styleCustomizer,
      // the editor is not editable in the chat
      editable: false,
      customPadding: (node) => EdgeInsets.zero,
    );

    return IgnorePointer(
      child: Opacity(
        opacity: reminder.type == ReminderType.past ? 0.3 : 1,
        child: AppFlowyEditor(
          editorState: editorState,
          editorStyle: editorStyle,
          disableSelectionService: true,
          disableKeyboardService: true,
          disableScrollService: true,
          editable: false,
          shrinkWrap: true,
          blockComponentBuilders: blockBuilders,
        ),
      ),
    );
  }
}
