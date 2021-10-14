import 'package:flowy_infra/image.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/trash_create.pb.dart';
import 'package:flutter/material.dart';

import 'sizes.dart';

class TrashCell extends StatelessWidget {
  final VoidCallback onRestore;
  final VoidCallback onDelete;
  final Trash object;
  const TrashCell({required this.object, required this.onRestore, required this.onDelete, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: TrashSizes.fileNameWidth, child: FlowyText(object.name, fontSize: 12)),
        SizedBox(width: TrashSizes.lashModifyWidth, child: FlowyText("${object.modifiedTime}", fontSize: 12)),
        SizedBox(width: TrashSizes.createTimeWidth, child: FlowyText("${object.createTime}", fontSize: 12)),
        const Spacer(),
        FlowyIconButton(
          width: 16,
          onPressed: onRestore,
          icon: svg("editor/restore"),
        ),
        const HSpace(20),
        FlowyIconButton(
          width: 16,
          onPressed: onDelete,
          icon: svg("editor/delete"),
        ),
        const HSpace(20),
      ],
    );
  }
}
