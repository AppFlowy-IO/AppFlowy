import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/base/flowy_search_text_field.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/show_mobile_bottom_sheet.dart';
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
    // title: LocaleKeys.document_mobilePageSelector_title.tr(),
    backgroundColor: Theme.of(context).colorScheme.surface,
    maxChildSize: 0.98,
    enableDraggableScrollable: true,
    builder: (context) => _MobilePageSelectorBody(filter: filter),
  );
}

class _MobilePageSelectorBody extends StatefulWidget {
  const _MobilePageSelectorBody({
    this.filter,
  });

  final bool Function(ViewPB view)? filter;

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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          height: 44.0,
          child: FlowySearchTextField(
            controller: textController,
            onChanged: (_) => setState(() {}),
          ),
        ),
        FutureBuilder(
          future: _viewsFuture,
          builder: (_, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator.adaptive();
            }

            if (snapshot.hasError || snapshot.data == null) {
              return FlowyText(
                LocaleKeys.document_mobilePageSelector_failedToLoad.tr(),
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
              return FlowyText(
                LocaleKeys.document_mobilePageSelector_noPagesFound.tr(),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemBuilder: (context, index) {
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
            );
          },
        ),
      ],
    );
  }

  Future<List<ViewPB>> _fetchViews() async =>
      (await ViewBackendService.getAllViews()).toNullable()?.items ?? [];
}
