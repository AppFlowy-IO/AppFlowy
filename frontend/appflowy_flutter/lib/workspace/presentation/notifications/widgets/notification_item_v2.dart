import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/application/notification/notification_reminder_bloc.dart';
import 'package:appflowy/mobile/presentation/notifications/widgets/widgets.dart';
import 'package:appflowy/plugins/document/application/document_data_pb_extension.dart';
import 'package:appflowy/plugins/document/application/document_service.dart';
import 'package:appflowy/user/application/reminder/reminder_bloc.dart';
import 'package:appflowy/user/application/reminder/reminder_extension.dart';
import 'package:appflowy/workspace/application/home/home_setting_bloc.dart';
import 'package:appflowy/workspace/application/settings/appearance/appearance_cubit.dart';
import 'package:appflowy/workspace/presentation/notifications/widgets/notification_tab_bar.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy_backend/protobuf/flowy-document/entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NotificationItemV2 extends StatelessWidget {
  const NotificationItemV2({
    super.key,
    required this.tabType,
    required this.reminder,
  });

  final NotificationTabType tabType;
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
          final reminderBloc = context.read<ReminderBloc>();
          final homeSetting = context.read<HomeSettingBloc>();
          if (state.status == NotificationReminderStatus.loading ||
              state.status == NotificationReminderStatus.initial) {
            return const SizedBox.shrink();
          }

          if (state.status == NotificationReminderStatus.error) {
            // error handle.
            return const SizedBox.shrink();
          }

          final child = Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: _InnerNotificationItem(
              tabType: tabType,
              reminder: reminder,
            ),
          );

          return FlowyHover(
            style: HoverStyle(
              hoverColor: Theme.of(context).colorScheme.secondary,
              borderRadius: BorderRadius.zero,
            ),
            resetHoverOnRebuild: false,
            builder: (context, hover) {
              return GestureDetector(
                behavior: HitTestBehavior.translucent,
                child: Stack(
                  children: [
                    child,
                    if (hover) buildActions(context),
                  ],
                ),
                onTap: () async {
                  final view = state.view;
                  if (view == null) {
                    return;
                  }

                  homeSetting.add(HomeSettingEvent.collapseNotificationPanel());

                  final documentFuture = DocumentService().openDocument(
                    documentId: reminder.objectId,
                  );

                  final blockId = reminder.meta[ReminderMetaKeys.blockId];

                  int? path;
                  if (blockId != null) {
                    final node =
                        await _getNodeFromDocument(documentFuture, blockId);
                    path = node?.path.first;
                  }

                  reminderBloc.add(
                    ReminderEvent.pressReminder(
                      reminderId: reminder.id,
                      path: path,
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget buildActions(BuildContext context) {
    const borderColor = Color(0x1F23291F);
    final decoration = BoxDecoration(
      border: Border.all(color: borderColor),
      borderRadius: BorderRadius.all(Radius.circular(6)),
      color: Theme.of(context).cardColor,
    );

    Widget child;
    if (tabType == NotificationTabType.archive) {
      child = Container(
        width: 32,
        height: 28,
        decoration: decoration,
        child: FlowyIconButton(
          tooltipText: LocaleKeys.notificationHub_unarchievedTooltip.tr(),
          icon: FlowySvg(FlowySvgs.notification_unarchive_s),
          onPressed: () {
            context.read<ReminderBloc>().add(
                  ReminderEvent.update(
                    ReminderUpdate(
                      id: reminder.id,
                      isArchived: false,
                    ),
                  ),
                );
          },
          width: 24,
          height: 24,
        ),
      );
    } else {
      child = Container(
        padding: EdgeInsets.fromLTRB(4, 2, 4, 2),
        decoration: decoration,
        child: Row(
          children: [
            if (!reminder.isRead) ...[
              FlowyIconButton(
                tooltipText: LocaleKeys.notificationHub_markAsReadTooltip.tr(),
                icon: FlowySvg(FlowySvgs.notification_markasread_s),
                width: 24,
                height: 24,
                onPressed: () {
                  context.read<ReminderBloc>().add(
                        ReminderEvent.update(
                          ReminderUpdate(
                            id: reminder.id,
                            isRead: true,
                          ),
                        ),
                      );

                  showToastNotification(
                    context,
                    message:
                        LocaleKeys.notificationHub_markAsReadSucceedToast.tr(),
                  );
                },
              ),
              HSpace(6),
            ],
            FlowyIconButton(
              tooltipText: LocaleKeys.notificationHub_archievedTooltip.tr(),
              icon: FlowySvg(
                FlowySvgs.notification_archive_s,
              ),
              width: 24,
              height: 24,
              onPressed: () {
                context.read<ReminderBloc>().add(
                      ReminderEvent.update(
                        ReminderUpdate(
                          id: reminder.id,
                          isArchived: true,
                          isRead: true,
                        ),
                      ),
                    );

                showToastNotification(
                  context,
                  message: LocaleKeys
                      .notificationHub_markAsArchievedSucceedToast
                      .tr(),
                );
              },
            ),
          ],
        ),
      );
    }
    return Positioned(
      top: 12,
      right: 14,
      child: child,
    );
  }

  Future<Node?> _getNodeFromDocument(
    Future<FlowyResult<DocumentDataPB, FlowyError>> documentFuture,
    String blockId,
  ) async {
    final document = (await documentFuture).fold(
      (document) => document,
      (_) => null,
    );

    if (document == null) {
      return null;
    }

    final rootNode = document.toDocument()?.root;
    if (rootNode == null) {
      return null;
    }

    return _searchById(rootNode, blockId);
  }

  Node? _searchById(Node current, String id) {
    if (current.id == id) {
      return current;
    }

    if (current.children.isNotEmpty) {
      for (final child in current.children) {
        final node = _searchById(child, id);

        if (node != null) {
          return node;
        }
      }
    }

    return null;
  }
}

class _InnerNotificationItem extends StatelessWidget {
  const _InnerNotificationItem({
    required this.reminder,
    required this.tabType,
  });

  final NotificationTabType tabType;
  final ReminderPB reminder;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        NotificationIcon(reminder: reminder),
        const HSpace(12.0),
        Expanded(
          child: NotificationContent(reminder: reminder),
        ),
      ],
    );
  }
}
