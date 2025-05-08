import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/search/mobile_search_cell.dart';
import 'package:appflowy/mobile/presentation/search/mobile_view_ancestors.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/header/emoji_icon_widget.dart';
import 'package:appflowy/shared/icon_emoji_picker/flowy_icon_emoji_picker.dart';
import 'package:appflowy/util/int64_extension.dart';
import 'package:appflowy/util/string_extension.dart';
import 'package:appflowy/workspace/application/command_palette/command_palette_bloc.dart';
import 'package:appflowy/workspace/application/command_palette/search_result_ext.dart';
import 'package:appflowy/workspace/application/command_palette/search_result_list_bloc.dart';
import 'package:appflowy/workspace/application/settings/appearance/appearance_cubit.dart';
import 'package:appflowy/workspace/application/settings/date_time/date_format_ext.dart';
import 'package:appflowy/workspace/application/view/prelude.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/presentation/command_palette/command_palette.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-search/result.pbenum.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flowy_infra_ui/widget/flowy_tooltip.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SearchResultCell extends StatefulWidget {
  const SearchResultCell({
    super.key,
    required this.item,
    this.query,
    this.isHovered = false,
  });

  final SearchResultItem item;
  final String? query;
  final bool isHovered;

  @override
  State<SearchResultCell> createState() => _SearchResultCellState();
}

class _SearchResultCellState extends State<SearchResultCell> {
  bool _hasFocus = false;
  final focusNode = FocusNode();

  String get viewId => item.id;
  SearchResultItem get item => widget.item;

  @override
  void dispose() {
    focusNode.dispose();
    super.dispose();
  }

  /// Helper to handle the selection action.
  void _handleSelection() {
    context.read<SearchResultListBloc>().add(
          SearchResultListEvent.openPage(pageId: viewId),
        );
  }

  @override
  Widget build(BuildContext context) {
    final title = item.displayName.orDefault(
      LocaleKeys.menuAppHeader_defaultNewPageName.tr(),
    );

    final theme = AppFlowyTheme.of(context);
    final textColor = theme.textColorScheme.primary;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _handleSelection,
      child: Focus(
        focusNode: focusNode,
        onKeyEvent: (node, event) {
          if (event is! KeyDownEvent) return KeyEventResult.ignored;
          if (event.logicalKey == LogicalKeyboardKey.enter) {
            _handleSelection();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        onFocusChange: (hasFocus) {
          setState(() {
            context.read<SearchResultListBloc>().add(
                  SearchResultListEvent.onHoverResult(
                    item: item,
                    userHovered: true,
                  ),
                );
            _hasFocus = hasFocus;
          });
        },
        child: FlowyHover(
          onHover: (value) {
            context.read<SearchResultListBloc>().add(
                  SearchResultListEvent.onHoverResult(
                    item: item,
                    userHovered: true,
                  ),
                );
          },
          isSelected: () => _hasFocus || widget.isHovered,
          style: HoverStyle(
            borderRadius: BorderRadius.circular(8),
            hoverColor: Theme.of(context).colorScheme.secondary,
            foregroundColorOnHover: AFThemeExtension.of(context).textColor,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox.square(
                  dimension: 24,
                  child: Center(child: buildIcon(theme)),
                ),
                HSpace(12),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        text: buildHighLightSpan(
                          content: title,
                          normal:
                              theme.textStyle.body.standard(color: textColor),
                          highlight: theme.textStyle.caption
                              .standard(color: textColor)
                              .copyWith(
                                backgroundColor:
                                    theme.fillColorScheme.themeSelect,
                              ),
                        ),
                      ),
                      buildPath(theme),
                      ...buildSummary(theme),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildIcon(AppFlowyThemeData theme) {
    final icon = item.icon;
    if (icon.ty == ResultIconTypePB.Emoji) {
      return icon.getIcon(size: 20) ?? SizedBox.shrink();
    } else {
      return icon.getIcon(size: 20, iconColor: theme.iconColorScheme.primary) ??
          SizedBox.shrink();
    }
  }

  Widget buildPath(AppFlowyThemeData theme) {
    return BlocProvider(
      key: ValueKey(viewId),
      create: (context) => ViewAncestorBloc(viewId),
      child: BlocBuilder<ViewAncestorBloc, ViewAncestorState>(
        builder: (context, state) => state.buildPath(context),
      ),
    );
  }

  TextSpan buildHighLightSpan({
    required String content,
    required TextStyle normal,
    required TextStyle highlight,
  }) {
    final queryText = (widget.query ?? '').trim();
    if (queryText.isEmpty) {
      return TextSpan(text: content, style: normal);
    }
    final contents = content.splitIncludeSeparator(queryText);
    return TextSpan(
      children: List.generate(contents.length, (index) {
        final content = contents[index];
        final isHighlight = content.toLowerCase() == queryText.toLowerCase();
        return TextSpan(
          text: content,
          style: isHighlight ? highlight : normal,
        );
      }),
    );
  }

  List<Widget> buildSummary(AppFlowyThemeData theme) {
    if (item.content.isEmpty) return [];
    return [
      VSpace(4),
      RichText(
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        text: buildHighLightSpan(
          content: item.content,
          normal: theme.textStyle.caption
              .standard(color: theme.textColorScheme.secondary),
          highlight: theme.textStyle.caption
              .standard(color: theme.textColorScheme.primary)
              .copyWith(
                backgroundColor: theme.fillColorScheme.themeSelect,
              ),
        ),
      ),
    ];
  }
}

class SearchResultPreview extends StatelessWidget {
  const SearchResultPreview({
    super.key,
    required this.item,
  });

  final SearchResultItem item;

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    return FutureBuilder(
      future: ViewBackendService.getView(item.id),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final view = snapshot.data?.toNullable();
        if (view == null) return NoSearchResultsHint();

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
      },
    );
  }

  Widget buildIcon(AppFlowyThemeData theme, ViewPB view) {
    return view.icon.value.isNotEmpty
        ? RawEmojiIconWidget(
            emoji: view.icon.toEmojiIconData(),
            emojiSize: 20.0,
            lineHeight: 1,
          )
        : FlowySvg(view.iconData, size: const Size.square(20));
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
