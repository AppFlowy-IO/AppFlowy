import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/settings/date_time/date_format_ext.dart';
import 'package:appflowy_backend/protobuf/flowy-user/date_time.pbenum.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';

class ViewMetaInfo extends StatelessWidget {
  const ViewMetaInfo({
    super.key,
    required this.dateFormat,
    required this.timeFormat,
    this.documentCounters,
    this.createdAt,
  });

  final UserDateFormatPB dateFormat;
  final UserTimeFormatPB timeFormat;
  final Counters? documentCounters;
  final DateTime? createdAt;

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat();

    // If more info is added to this Widget, use a separated ListView
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (documentCounters != null) ...[
            FlowyText.regular(
              LocaleKeys.moreAction_wordCount.tr(
                args: [
                  numberFormat.format(documentCounters!.wordCount).toString(),
                ],
              ),
              fontSize: 12,
              color: Theme.of(context).hintColor,
            ),
            const VSpace(2),
            FlowyText.regular(
              LocaleKeys.moreAction_charCount.tr(
                args: [
                  numberFormat.format(documentCounters!.charCount).toString(),
                ],
              ),
              fontSize: 12,
              color: Theme.of(context).hintColor,
            ),
          ],
          if (createdAt != null) ...[
            if (documentCounters != null) const VSpace(2),
            FlowyText.regular(
              LocaleKeys.moreAction_createdAt.tr(
                args: [dateFormat.formatDate(createdAt!, true, timeFormat)],
              ),
              fontSize: 12,
              maxLines: 2,
              color: Theme.of(context).hintColor,
            ),
          ],
        ],
      ),
    );
  }
}
