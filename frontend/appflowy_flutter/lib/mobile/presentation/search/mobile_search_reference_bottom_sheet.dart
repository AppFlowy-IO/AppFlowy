import 'package:appflowy/mobile/presentation/base/mobile_view_page.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/show_mobile_bottom_sheet.dart';
import 'package:appflowy/shared/icon_emoji_picker/tab.dart';
import 'package:appflowy/startup/tasks/app_widget.dart';
import 'package:appflowy/workspace/application/command_palette/search_result_ext.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy_backend/protobuf/flowy-search/result.pb.dart';
import 'package:flutter/material.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flowy_infra_ui/flowy_infra_ui.dart';

class SearchSourceReferenceBottomSheet extends StatelessWidget {
  const SearchSourceReferenceBottomSheet(this.sources, {super.key});

  final List<SearchSourcePB> sources;
  @override
  Widget build(BuildContext context) {
    return PageReferenceList(
      sources: sources,
      onTap: (id) async {
        final theme = AppFlowyTheme.of(context);
        final view = (await ViewBackendService.getView(id)).toNullable();
        if (view == null) {
          showToastNotification(
            message: LocaleKeys.search_somethingWentWrong.tr(),
            type: ToastificationType.error,
          );
          return;
        }
        await showMobileBottomSheet(
          AppGlobals.rootNavKey.currentContext ?? context,
          showDragHandle: true,
          showDivider: false,
          enableDraggableScrollable: true,
          maxChildSize: 1.0,
          minChildSize: 1.0,
          initialChildSize: 1.0,
          backgroundColor: theme.surfaceColorScheme.primary,
          builder: (_) => SizedBox(
            height: MediaQuery.of(context).size.height,
            child: MobileViewPage(
              id: id,
              viewLayout: view.layout,
              title: view.nameOrDefault,
              tabs: PickerTabType.values,
            ),
          ),
        );
      },
    );
  }
}

class PageReferenceList extends StatelessWidget {
  const PageReferenceList({
    super.key,
    required this.sources,
    required this.onTap,
  });

  final List<SearchSourcePB> sources;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, top: 8),
          child: Text(
            LocaleKeys.commandPalette_aiOverviewSource.tr(),
            style: theme.textStyle.body.enhanced(
              color: theme.textColorScheme.secondary,
            ),
          ),
        ),
        const VSpace(6),
        ListView.builder(
          shrinkWrap: true,
          padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            final source = sources[index];
            final displayName = source.displayName.isEmpty
                ? LocaleKeys.menuAppHeader_defaultNewPageName.tr()
                : source.displayName;
            final sapceM = theme.spacing.m, spaceL = theme.spacing.l;
            return FlowyButton(
              onTap: () => onTap.call(source.id),
              margin: EdgeInsets.zero,
              text: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (index != 0) AFDivider(),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: spaceL,
                      horizontal: sapceM,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox.square(
                          dimension: 20,
                          child: Center(child: buildIcon(source.icon, theme)),
                        ),
                        HSpace(12),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textStyle.heading4.standard(
                                  color: theme.textColorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
          itemCount: sources.length,
        ),
      ],
    );
  }

  Widget buildIcon(ResultIconPB icon, AppFlowyThemeData theme) {
    if (icon.ty == ResultIconTypePB.Emoji) {
      return icon.getIcon(size: 16, lineHeight: 20 / 16) ?? SizedBox.shrink();
    } else {
      return icon.getIcon(size: 20, iconColor: theme.iconColorScheme.primary) ??
          SizedBox.shrink();
    }
  }
}
