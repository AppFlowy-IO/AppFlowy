import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/icon/icon_selector.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/page_style/_page_style_icon_bloc.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/page_style/_page_style_util.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class PageStyleIcon extends StatefulWidget {
  const PageStyleIcon({
    super.key,
    required this.view,
  });

  final ViewPB view;

  @override
  State<PageStyleIcon> createState() => _PageStyleIconState();
}

class _PageStyleIconState extends State<PageStyleIcon> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PageStyleIconBloc(view: widget.view)
        ..add(const PageStyleIconEvent.initial()),
      child: BlocBuilder<PageStyleIconBloc, PageStyleIconState>(
        builder: (context, state) {
          final icon = state.icon ?? '';
          return GestureDetector(
            onTap: () => _showIconSelector(context, icon),
            behavior: HitTestBehavior.opaque,
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: context.pageStyleBackgroundColor,
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Row(
                children: [
                  const HSpace(16.0),
                  FlowyText(LocaleKeys.document_plugins_emoji.tr()),
                  const Spacer(),
                  FlowyText(
                    icon.isNotEmpty ? icon : LocaleKeys.pageStyle_none.tr(),
                    color: icon.isEmpty ? context.pageStyleTextColor : null,
                    fontSize: icon.isNotEmpty ? 22.0 : 16.0,
                  ),
                  const HSpace(6.0),
                  const FlowySvg(FlowySvgs.m_page_style_arrow_right_s),
                  const HSpace(12.0),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showIconSelector(BuildContext context, String selectedIcon) {
    context.pop();

    final pageStyleIconBloc = PageStyleIconBloc(view: widget.view)
      ..add(const PageStyleIconEvent.initial());
    showMobileBottomSheet(
      context,
      showDragHandle: true,
      showDivider: false,
      showDoneButton: true,
      showHeader: true,
      title: LocaleKeys.titleBar_pageIcon.tr(),
      backgroundColor: AFThemeExtension.of(context).background,
      enableDraggableScrollable: true,
      minChildSize: 0.6,
      initialChildSize: 0.61,
      showRemoveButton: true,
      onRemove: () {
        pageStyleIconBloc.add(
          const PageStyleIconEvent.updateIcon('', true),
        );
      },
      scrollableWidgetBuilder: (_, controller) {
        return BlocProvider.value(
          value: pageStyleIconBloc,
          child: Expanded(
            child: Scrollbar(
              controller: controller,
              child: IconSelector(
                scrollController: controller,
              ),
            ),
          ),
        );
      },
      builder: (_) => const SizedBox.shrink(),
    );
  }
}
