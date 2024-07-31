import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/application/notification/notification_reminder_bloc.dart';
import 'package:appflowy/mobile/application/page_style/document_page_style_bloc.dart';
import 'package:appflowy/mobile/presentation/base/gesture.dart';
import 'package:appflowy/mobile/presentation/notifications/widgets/color.dart';
import 'package:appflowy/mobile/presentation/notifications/widgets/widgets.dart';
import 'package:appflowy/plugins/document/presentation/editor_configuration.dart';
import 'package:appflowy/plugins/document/presentation/editor_style.dart';
import 'package:appflowy/user/application/reminder/reminder_bloc.dart';
import 'package:appflowy/workspace/application/settings/appearance/appearance_cubit.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class NotificationItem extends StatelessWidget {
  const NotificationItem({
    super.key,
    required this.tabType,
    required this.reminder,
  });

  final MobileNotificationTabType tabType;
  final ReminderPB reminder;

  @override
  Widget build(BuildContext context) {
    final settings = context.read<AppearanceSettingsCubit>().state;
    final dateFormate = settings.dateFormat;
    final timeFormate = settings.timeFormat;
    return BlocProvider<NotificationReminderBloc>(
      create: (context) => NotificationReminderBloc()
        ..add(
          NotificationReminderEvent.initial(
            reminder,
            dateFormate,
            timeFormate,
          ),
        ),
      child: BlocBuilder<NotificationReminderBloc, NotificationReminderState>(
        builder: (context, state) {
          if (state.status == NotificationReminderStatus.loading ||
              state.status == NotificationReminderStatus.initial) {
            return const SizedBox.shrink();
          }

          if (state.status == NotificationReminderStatus.error) {
            // error handle.
            return const SizedBox.shrink();
          }

          final child = Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: _SlidableNotificationItem(
              tabType: tabType,
              reminder: reminder,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const HSpace(8.0),
                  !reminder.isRead ? const _UnreadRedDot() : const HSpace(6.0),
                  const HSpace(4.0),
                  _NotificationIcon(reminder: reminder),
                  const HSpace(12.0),
                  Expanded(
                    child: _NotificationContent(reminder: reminder),
                  ),
                ],
              ),
            ),
          );

          if (reminder.isRead) {
            return child;
          }

          return AnimatedGestureDetector(
            scaleFactor: 0.99,
            onTapUp: () => _onMarkAsRead(context),
            child: child,
          );
        },
      ),
    );
  }

  void _onMarkAsRead(BuildContext context) {
    if (reminder.isRead) {
      return;
    }

    showToastNotification(
      context,
      message: LocaleKeys.settings_notifications_markAsReadNotifications_success
          .tr(),
    );

    context.read<ReminderBloc>().add(
          ReminderEvent.update(
            ReminderUpdate(
              id: context.read<NotificationReminderBloc>().reminder.id,
              isRead: true,
            ),
          ),
        );
  }
}

class _SlidableNotificationItem extends StatelessWidget {
  const _SlidableNotificationItem({
    required this.tabType,
    required this.reminder,
    required this.child,
  });

  final MobileNotificationTabType tabType;
  final ReminderPB reminder;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // only show the actions in the inbox tab

    final List<NotificationPaneActionType> actions = switch (tabType) {
      MobileNotificationTabType.inbox => [
          NotificationPaneActionType.more,
          if (!reminder.isRead) NotificationPaneActionType.markAsRead,
        ],
      MobileNotificationTabType.unread => [
          NotificationPaneActionType.more,
          NotificationPaneActionType.markAsRead,
        ],
      MobileNotificationTabType.archive => [
          if (kDebugMode) NotificationPaneActionType.unArchive,
        ],
    };

    if (actions.isEmpty) {
      return child;
    }

    final children = actions
        .map(
          (action) => action.actionButton(
            context,
            tabType: tabType,
          ),
        )
        .toList();

    final extentRatio = actions.length == 1 ? 1 / 5 : 1 / 3;

    return Slidable(
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        extentRatio: extentRatio,
        children: children,
      ),
      child: child,
    );
  }
}

const _kNotificationIconHeight = 36.0;

class _NotificationIcon extends StatelessWidget {
  const _NotificationIcon({
    required this.reminder,
  });

  final ReminderPB reminder;

  @override
  Widget build(BuildContext context) {
    return const FlowySvg(
      FlowySvgs.m_notification_reminder_s,
      size: Size.square(_kNotificationIconHeight),
      blendMode: null,
    );
  }
}

class _UnreadRedDot extends StatelessWidget {
  const _UnreadRedDot();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: _kNotificationIconHeight,
      child: Center(
        child: SizedBox.square(
          dimension: 6.0,
          child: DecoratedBox(
            decoration: ShapeDecoration(
              color: Color(0xFFFF6331),
              shape: OvalBorder(),
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationContent extends StatelessWidget {
  const _NotificationContent({
    required this.reminder,
  });

  final ReminderPB reminder;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationReminderBloc, NotificationReminderState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // title
            _buildHeader(),

            // time & page name
            _buildTimeAndPageName(
              context,
              state.createdAt,
              state.pageTitle,
            ),

            // content
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: IntrinsicHeight(
                child: BlocProvider(
                  create: (context) => DocumentPageStyleBloc(view: state.view!),
                  child: _NotificationDocumentContent(nodes: state.nodes),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader() {
    return FlowyText.semibold(
      LocaleKeys.settings_notifications_titles_reminder.tr(),
      fontSize: 14,
      figmaLineHeight: 20,
    );
  }

  Widget _buildTimeAndPageName(
    BuildContext context,
    String createdAt,
    String pageTitle,
  ) {
    return Opacity(
      opacity: 0.5,
      child: Row(
        children: [
          // the legacy reminder doesn't contain the timestamp, so we don't show it
          if (createdAt.isNotEmpty) ...[
            FlowyText.regular(
              createdAt,
              fontSize: 12,
              figmaLineHeight: 18,
              color: context.notificationItemTextColor,
            ),
            const _Ellipse(),
          ],
          FlowyText.regular(
            pageTitle,
            fontSize: 12,
            figmaLineHeight: 18,
            color: context.notificationItemTextColor,
          ),
        ],
      ),
    );
  }
}

class _Ellipse extends StatelessWidget {
  const _Ellipse();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 2.50,
      height: 2.50,
      margin: const EdgeInsets.symmetric(horizontal: 5.0),
      decoration: ShapeDecoration(
        color: context.notificationItemTextColor,
        shape: const OvalBorder(),
      ),
    );
  }
}

class _NotificationDocumentContent extends StatelessWidget {
  const _NotificationDocumentContent({
    required this.nodes,
  });

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

    final blockBuilders = getEditorBuilderMap(
      context: context,
      editorState: editorState,
      styleCustomizer: styleCustomizer,
      // the editor is not editable in the chat
      editable: false,
      customHeadingPadding: EdgeInsets.zero,
    );

    return AppFlowyEditor(
      editorState: editorState,
      editorStyle: editorStyle,
      disableSelectionService: true,
      disableKeyboardService: true,
      disableScrollService: true,
      editable: false,
      shrinkWrap: true,
      blockComponentBuilders: blockBuilders,
    );
  }
}
