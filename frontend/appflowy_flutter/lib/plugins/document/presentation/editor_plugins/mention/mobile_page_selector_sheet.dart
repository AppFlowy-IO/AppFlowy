import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/base/flowy_search_text_field.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/show_mobile_bottom_sheet.dart';
import 'package:appflowy/mobile/presentation/widgets/widgets.dart';
import 'package:appflowy/plugins/base/emoji/emoji_text.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/material.dart';

Future<ViewPB?> showPageSelectorSheet(
  BuildContext context, {
  String? currentViewId,
  String? selectedViewId,
  bool Function(ViewPB view)? filter,
}) async {
  filter ??= (v) => !v.isSpace && v.parentViewId.isNotEmpty;

  return showMobileBottomSheet<ViewPB>(
    context,
    title: LocaleKeys.document_mobilePageSelector_title.tr(),
    showHeader: true,
    showCloseButton: true,
    showDragHandle: true,
    builder: (context) => Container(
      margin: const EdgeInsets.only(top: 12.0),
      constraints: const BoxConstraints(
        maxHeight: 340,
        minHeight: 80,
      ),
      child: _MobilePageSelectorBody(
        currentViewId: currentViewId,
        selectedViewId: selectedViewId,
        filter: filter,
      ),
    ),
  );
}

class _MobilePageSelectorBody extends StatefulWidget {
  const _MobilePageSelectorBody({
    this.currentViewId,
    this.selectedViewId,
    this.filter,
  });

  final String? currentViewId;
  final String? selectedViewId;
  final bool Function(ViewPB view)? filter;

  @override
  State<_MobilePageSelectorBody> createState() =>
      _MobilePageSelectorBodyState();
}

class _MobilePageSelectorBodyState extends State<_MobilePageSelectorBody> {
  final searchController = TextEditingController();
  late final Future<List<ViewPB>> _viewsFuture = _fetchViews();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          height: 44.0,
          child: FlowySearchTextField(
            controller: searchController,
            onChanged: (_) => setState(() {}),
          ),
        ),
        FutureBuilder(
          future: _viewsFuture,
          builder: (_, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator.adaptive());
            }

            if (snapshot.hasError || snapshot.data == null) {
              return Center(
                child: FlowyText(
                  LocaleKeys.document_mobilePageSelector_failedToLoad.tr(),
                ),
              );
            }

            final views = snapshot.data!
                .where((v) => widget.filter?.call(v) ?? true)
                .toList();

            if (widget.currentViewId != null) {
              views.removeWhere((v) => v.id == widget.currentViewId);
            }

            final filtered = views.where(
              (v) =>
                  searchController.text.isEmpty ||
                  v.name
                      .toLowerCase()
                      .contains(searchController.text.toLowerCase()),
            );

            if (filtered.isEmpty) {
              return Center(
                child: FlowyText(
                  LocaleKeys.document_mobilePageSelector_noPagesFound.tr(),
                ),
              );
            }

            return Flexible(
              child: ListView(
                children: filtered
                    .map(
                      (view) => FlowyOptionTile.checkbox(
                        leftIcon: view.icon.value.isNotEmpty
                            ? EmojiText(
                                emoji: view.icon.value,
                                fontSize: 18,
                                textAlign: TextAlign.center,
                                lineHeight: 1.3,
                              )
                            : FlowySvg(
                                view.layout.icon,
                                size: const Size.square(20),
                              ),
                        text: view.name,
                        isSelected: view.id == widget.selectedViewId,
                        onTap: () => Navigator.of(context).pop(view),
                      ),
                    )
                    .toList(),
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
