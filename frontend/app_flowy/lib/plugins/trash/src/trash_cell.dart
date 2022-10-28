import 'package:flowy_infra/image.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flowy_sdk/protobuf/flowy-folder/trash.pb.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fixnum/fixnum.dart' as $fixnum;

import 'sizes.dart';

class TrashCell extends StatelessWidget {
  final VoidCallback onRestore;
  final VoidCallback onDelete;
  final TrashPB object;
  const TrashCell(
      {required this.object,
      required this.onRestore,
      required this.onDelete,
      Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
            width: TrashSizes.fileNameWidth,
            child: FlowyText(object.name, fontSize: 12)),
        SizedBox(
            width: TrashSizes.lashModifyWidth,
            child: FlowyText(dateFormatter(object.modifiedTime), fontSize: 12)),
        SizedBox(
            width: TrashSizes.createTimeWidth,
            child: FlowyText(dateFormatter(object.createTime), fontSize: 12)),
        const Spacer(),
        FlowyIconButton(
          width: 26,
          onPressed: onRestore,
          hoverColor: Theme.of(context).colorScheme.secondary,
          iconPadding: const EdgeInsets.all(5),
          icon: svgWidget(
            "editor/restore",
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const HSpace(20),
        FlowyIconButton(
          width: 26,
          onPressed: onDelete,
          hoverColor: Theme.of(context).colorScheme.secondary,
          iconPadding: const EdgeInsets.all(5),
          icon: svgWidget(
            "editor/delete",
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  String dateFormatter($fixnum.Int64 inputTimestamps) {
    var outputFormat = DateFormat('MM/dd/yyyy hh:mm a');
    var date =
        DateTime.fromMillisecondsSinceEpoch(inputTimestamps.toInt() * 1000);
    var outputDate = outputFormat.format(date);
    return outputDate;
  }
}
