import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/trash.pb.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fixnum/fixnum.dart' as $fixnum;

import 'sizes.dart';

class TrashCell extends StatelessWidget {
  const TrashCell({
    super.key,
    required this.object,
    required this.onRestore,
    required this.onDelete,
  });

  final VoidCallback onRestore;
  final VoidCallback onDelete;
  final TrashPB object;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: TrashSizes.fileNameWidth,
          child: FlowyText(object.name),
        ),
        SizedBox(
          width: TrashSizes.lashModifyWidth,
          child: FlowyText(dateFormatter(object.modifiedTime)),
        ),
        SizedBox(
          width: TrashSizes.createTimeWidth,
          child: FlowyText(dateFormatter(object.createTime)),
        ),
        const Spacer(),
        FlowyIconButton(
          iconColorOnHover: Theme.of(context).colorScheme.onSurface,
          width: TrashSizes.actionIconWidth,
          onPressed: onRestore,
          iconPadding: const EdgeInsets.all(5),
          icon: const FlowySvg(FlowySvgs.restore_s),
        ),
        const HSpace(20),
        FlowyIconButton(
          iconColorOnHover: Theme.of(context).colorScheme.onSurface,
          width: TrashSizes.actionIconWidth,
          onPressed: onDelete,
          iconPadding: const EdgeInsets.all(5),
          icon: const FlowySvg(FlowySvgs.delete_s),
        ),
      ],
    );
  }

  String dateFormatter($fixnum.Int64 inputTimestamps) {
    final outputFormat = DateFormat('MM/dd/yyyy hh:mm a');
    final date =
        DateTime.fromMillisecondsSinceEpoch(inputTimestamps.toInt() * 1000);
    final outputDate = outputFormat.format(date);
    return outputDate;
  }
}
