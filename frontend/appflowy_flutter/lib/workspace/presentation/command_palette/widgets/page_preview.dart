import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/search/mobile_view_ancestors.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/header/emoji_icon_widget.dart';
import 'package:appflowy/shared/icon_emoji_picker/flowy_icon_emoji_picker.dart';
import 'package:appflowy/util/int64_extension.dart';
import 'package:appflowy/workspace/application/command_palette/search_result_list_bloc.dart';
import 'package:appflowy/workspace/application/settings/appearance/appearance_cubit.dart';
import 'package:appflowy/workspace/application/settings/date_time/date_format_ext.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PagePreview extends StatelessWidget {
  const PagePreview({super.key, required this.view});
  final ViewPB view;

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox.square(
              dimension: 24,
              child: Center(child: buildIcon(theme, view)),
            ),
            VSpace(8),
            buildTitle(context, view),
            buildPath(context, view),
            ...buildTime(
              context,
              LocaleKeys.commandPalette_created.tr(),
              view.createTime.toDateTime(),
            ),
            if (view.lastEdited != view.createTime)
              ...buildTime(
                context,
                LocaleKeys.commandPalette_edited.tr(),
                view.lastEdited.toDateTime(),
              ),
          ],
        ),
      ),
    );
  }

  Widget buildIcon(AppFlowyThemeData theme, ViewPB view) {
    return view.icon.value.isNotEmpty
        ? RawEmojiIconWidget(
            emoji: view.icon.toEmojiIconData(),
            emojiSize: 20.0,
            lineHeight: 1,
          )
        : FlowySvg(
            view.iconData,
            size: const Size.square(20),
            color: theme.iconColorScheme.secondary,
          );
  }

  Widget buildTitle(BuildContext context, ViewPB view) {
    final theme = AppFlowyTheme.of(context);
    return SizedBox(
      height: 28,
      child: Row(
        children: [
          Flexible(
            child: Text(
              view.nameOrDefault,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textStyle.heading4.enhanced(
                color: theme.textColorScheme.primary,
              ),
            ),
          ),
          HSpace(4),
          FlowyTooltip(
            message: LocaleKeys.settings_files_open.tr(),
            child: AFGhostButton.normal(
              size: AFButtonSize.s,
              padding: EdgeInsets.all(theme.spacing.xs),
              onTap: () {
                context.read<SearchResultListBloc?>()?.add(
                      SearchResultListEvent.openPage(pageId: view.id),
                    );
              },
              builder: (context, isHovering, disabled) => FlowySvg(
                FlowySvgs.search_arrow_right_m,
                size: const Size.square(20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildPath(BuildContext context, ViewPB view) {
    final theme = AppFlowyTheme.of(context);
    return BlocProvider(
      key: ValueKey(view.id),
      create: (context) => ViewAncestorBloc(view.id),
      child: BlocBuilder<ViewAncestorBloc, ViewAncestorState>(
        builder: (context, state) {
          if (state.ancestor.ancestors.isEmpty) return const SizedBox.shrink();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              VSpace(16),
              Text(
                LocaleKeys.commandPalette_location.tr(),
                style: theme.textStyle.caption
                    .standard(color: theme.textColorScheme.primary),
              ),
              state.buildPath(
                context,
                style: theme.textStyle.caption.standard(
                  color: theme.textColorScheme.secondary,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> buildTime(BuildContext context, String title, DateTime time) {
    final theme = AppFlowyTheme.of(context);
    final appearanceSettings = context.watch<AppearanceSettingsCubit>().state;
    final dateFormat = appearanceSettings.dateFormat,
        timeFormat = appearanceSettings.timeFormat;
    return [
      VSpace(12),
      Text(
        title,
        style: theme.textStyle.caption
            .standard(color: theme.textColorScheme.primary),
      ),
      Text(
        dateFormat.formatDate(time, true, timeFormat),
        style: theme.textStyle.caption
            .standard(color: theme.textColorScheme.secondary),
      ),
    ];
  }
}

class SomethingWentWrong extends StatelessWidget {
  const SomethingWentWrong({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FlowySvg(
            FlowySvgs.something_wrong_warning_m,
            color: theme.iconColorScheme.secondary,
            size: Size.square(24),
          ),
          const VSpace(8),
          Text(
            LocaleKeys.search_somethingWentWrong.tr(),
            style: theme.textStyle.body
                .enhanced(color: theme.textColorScheme.secondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const VSpace(4),
          Text(
            LocaleKeys.search_tryAgainOrLater.tr(),
            style: theme.textStyle.caption
                .standard(color: theme.textColorScheme.secondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
