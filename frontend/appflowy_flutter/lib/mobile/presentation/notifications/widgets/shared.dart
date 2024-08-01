import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/application/notification/notification_reminder_bloc.dart';
import 'package:appflowy/mobile/application/page_style/document_page_style_bloc.dart';
import 'package:appflowy/mobile/presentation/notifications/widgets/color.dart';
import 'package:appflowy/plugins/document/presentation/editor_configuration.dart';
import 'package:appflowy/plugins/document/presentation/editor_style.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
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
    return const FlowySvg(
      FlowySvgs.m_notification_reminder_s,
      size: Size.square(_kNotificationIconHeight),
      blendMode: null,
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

class NotificationContent extends StatelessWidget {
  const NotificationContent({
    super.key,
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
                  child: NotificationDocumentContent(nodes: state.nodes),
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
            const NotificationEllipse(),
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

class NotificationEllipse extends StatelessWidget {
  const NotificationEllipse({super.key});

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

class NotificationDocumentContent extends StatelessWidget {
  const NotificationDocumentContent({
    super.key,
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
