import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/base/flowy_search_text_field.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/show_mobile_bottom_sheet.dart';
import 'package:appflowy/plugins/base/drag_handler.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

import 'chat_mention_page_menu.dart';

Future<ViewPB?> showPageSelectorSheet(
  BuildContext context, {
  bool Function(ViewPB view)? filter,
}) async {
  filter ??= (v) => !v.isSpace && v.parentViewId.isNotEmpty;

  return showMobileBottomSheet<ViewPB>(
    context,
    backgroundColor: Theme.of(context).colorScheme.surface,
    maxChildSize: 0.98,
    enableDraggableScrollable: true,
    scrollableWidgetBuilder: (context, scrollController) {
      return Expanded(
        child: _MobilePageSelectorBody(
          filter: filter,
          scrollController: scrollController,
        ),
      );
    },
    builder: (context) => const SizedBox.shrink(),
  );
}

class _MobilePageSelectorBody extends StatefulWidget {
  const _MobilePageSelectorBody({
    this.filter,
    this.scrollController,
  });

  final bool Function(ViewPB view)? filter;
  final ScrollController? scrollController;

  @override
  State<_MobilePageSelectorBody> createState() =>
      _MobilePageSelectorBodyState();
}

class _MobilePageSelectorBodyState extends State<_MobilePageSelectorBody> {
  final textController = TextEditingController();
  late final Future<List<ViewPB>> _viewsFuture = _fetchViews();

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: widget.scrollController,
      shrinkWrap: true,
      slivers: [
        SliverPersistentHeader(
          pinned: true,
          delegate: _Header(
            child: ColoredBox(
              color: Theme.of(context).cardColor,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const DragHandle(),
                  SizedBox(
                    height: 44.0,
                    child: Center(
                      child: FlowyText.medium(
                        LocaleKeys.document_mobilePageSelector_title.tr(),
                        fontSize: 16.0,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: SizedBox(
                      height: 44.0,
                      child: FlowySearchTextField(
                        controller: textController,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ),
                  const Divider(height: 0.5, thickness: 0.5),
                ],
              ),
            ),
          ),
        ),
        FutureBuilder(
          future: _viewsFuture,
          builder: (_, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SliverToBoxAdapter(
                child: CircularProgressIndicator.adaptive(),
              );
            }

            if (snapshot.hasError || snapshot.data == null) {
              return SliverToBoxAdapter(
                child: FlowyText(
                  LocaleKeys.document_mobilePageSelector_failedToLoad.tr(),
                ),
              );
            }

            final views = snapshot.data!
                .where((v) => widget.filter?.call(v) ?? true)
                .toList();

            final filtered = views.where(
              (v) =>
                  textController.text.isEmpty ||
                  v.name
                      .toLowerCase()
                      .contains(textController.text.toLowerCase()),
            );

            if (filtered.isEmpty) {
              return SliverToBoxAdapter(
                child: FlowyText(
                  LocaleKeys.document_mobilePageSelector_noPagesFound.tr(),
                ),
              );
            }

            return SliverPadding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final view = filtered.elementAt(index);
                    return InkWell(
                      onTap: () => Navigator.of(context).pop(view),
                      borderRadius: BorderRadius.circular(12),
                      splashColor: Colors.transparent,
                      child: Container(
                        height: 44,
                        padding: const EdgeInsets.all(4.0),
                        child: Row(
                          children: [
                            MentionViewIcon(view: view),
                            const HSpace(8),
                            Expanded(
                              child: MentionViewTitleAndAncestors(view: view),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: filtered.length,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Future<List<ViewPB>> _fetchViews() async =>
      (await ViewBackendService.getAllViews()).toNullable()?.items ?? [];
}

class _Header extends SliverPersistentHeaderDelegate {
  const _Header({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  double get maxExtent => 120.5;

  @override
  double get minExtent => 120.5;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}
