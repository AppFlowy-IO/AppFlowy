import 'dart:io';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/application/page_style/document_page_style_bloc.dart';
import 'package:appflowy/mobile/presentation/search/mobile_view_ancestors.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/cover/document_immersive_cover_bloc.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/header/emoji_icon_widget.dart';
import 'package:appflowy/shared/appflowy_network_image.dart';
import 'package:appflowy/shared/flowy_gradient_colors.dart';
import 'package:appflowy/shared/icon_emoji_picker/flowy_icon_emoji_picker.dart';
import 'package:appflowy/util/int64_extension.dart';
import 'package:appflowy/util/theme_extension.dart';
import 'package:appflowy/workspace/application/settings/appearance/appearance_cubit.dart';
import 'package:appflowy/workspace/application/settings/date_time/date_format_ext.dart';
import 'package:appflowy/workspace/application/user/user_workspace_bloc.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PagePreview extends StatelessWidget {
  const PagePreview({
    super.key,
    required this.view,
    required this.onViewOpened,
  });
  final ViewPB view;
  final VoidCallback onViewOpened;

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    final backgroundColor = Theme.of(context).isLightMode
        ? Color(0xffF8FAFF)
        : theme.surfaceColorScheme.layer02;

    return BlocProvider(
      create: (context) => DocumentImmersiveCoverBloc(view: view)
        ..add(const DocumentImmersiveCoverEvent.initial()),
      child:
          BlocBuilder<DocumentImmersiveCoverBloc, DocumentImmersiveCoverState>(
        builder: (context, state) {
          final cover = buildCover(state, context);
          return Container(
            height: MediaQuery.of(context).size.height,
            width: 280,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            margin: EdgeInsets.symmetric(vertical: 16),
            child: Stack(
              children: [
                SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                        child: cover ?? VSpace(80),
                      ),
                      VSpace(24),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
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
                    ],
                  ),
                ),
                Positioned(
                  top: 70,
                  left: 20,
                  child: SizedBox.square(
                    dimension: 24,
                    child: Center(child: buildIcon(theme, view, cover != null)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget? buildCover(DocumentImmersiveCoverState state, BuildContext context) {
    final cover = state.cover;
    final type = state.cover.type;
    const height = 80.0;
    if (type == PageStyleCoverImageType.customImage ||
        type == PageStyleCoverImageType.unsplashImage) {
      final userProfile = context.read<UserWorkspaceBloc?>()?.state.userProfile;
      if (userProfile == null) return null;

      return SizedBox(
        height: height,
        width: double.infinity,
        child: FlowyNetworkImage(
          url: cover.value,
          userProfilePB: userProfile,
        ),
      );
    }

    if (type == PageStyleCoverImageType.builtInImage) {
      return SizedBox(
        height: height,
        width: double.infinity,
        child: Image.asset(
          PageStyleCoverImageType.builtInImagePath(cover.value),
          fit: BoxFit.cover,
        ),
      );
    }

    if (type == PageStyleCoverImageType.pureColor) {
      final color = FlowyTint.fromId(cover.value)?.color(context) ??
          cover.value.tryToColor();
      return Container(
        height: height,
        width: double.infinity,
        color: color,
      );
    }

    if (type == PageStyleCoverImageType.gradientColor) {
      return Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: FlowyGradientColor.fromId(cover.value).linear,
        ),
      );
    }

    if (type == PageStyleCoverImageType.localImage) {
      return SizedBox(
        height: height,
        width: double.infinity,
        child: Image.file(
          File(cover.value),
          fit: BoxFit.cover,
        ),
      );
    }

    return null;
  }

  Widget buildIcon(AppFlowyThemeData theme, ViewPB view, bool hasCover) {
    final hasIcon = view.icon.value.isNotEmpty;
    if (!hasIcon && hasCover) return const SizedBox.shrink();
    return hasIcon
        ? RawEmojiIconWidget(
            emoji: view.icon.toEmojiIconData(),
            emojiSize: 16.0,
            lineHeight: 20 / 16,
          )
        : FlowySvg(
            view.iconData,
            size: const Size.square(20),
            color: theme.iconColorScheme.secondary,
          );
  }

  Widget buildTitle(BuildContext context, ViewPB view) {
    final theme = AppFlowyTheme.of(context);
    final titleStyle = theme.textStyle.heading4
            .enhanced(color: theme.textColorScheme.primary),
        titleHoverStyle =
            titleStyle.copyWith(decoration: TextDecoration.underline);
    return SizedBox(
      height: 28,
      child: Row(
        children: [
          Flexible(
            child: AFBaseButton(
              padding: EdgeInsets.zero,
              builder: (context, isHovering, disabled) =>
                  SelectionContainer.disabled(
                child: Text(
                  view.nameOrDefault,
                  style: isHovering ? titleHoverStyle : titleStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              borderColor: (_, __, ___, ____) => Colors.transparent,
              borderRadius: 0,
              onTap: onViewOpened,
            ),
          ),
          HSpace(4),
          FlowyTooltip(
            message: LocaleKeys.settings_files_open.tr(),
            child: AFGhostButton.normal(
              size: AFButtonSize.s,
              padding: EdgeInsets.all(theme.spacing.xs),
              onTap: onViewOpened,
              builder: (context, isHovering, disabled) => FlowySvg(
                FlowySvgs.search_open_tab_m,
                color: theme.iconColorScheme.secondary,
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
          final isEmpty = state.ancestor.ancestors.isEmpty;
          if (!state.isLoading && isEmpty) return const SizedBox.shrink();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              VSpace(20),
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
