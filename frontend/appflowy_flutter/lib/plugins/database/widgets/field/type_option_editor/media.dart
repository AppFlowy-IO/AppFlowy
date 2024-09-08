import 'package:flutter/material.dart';

import 'package:appflowy/plugins/database/widgets/field/type_option_editor/builder.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pb.dart';
import 'package:appflowy_popover/appflowy_popover.dart';

class MediaTypeOptionEditorFactory implements TypeOptionEditorFactory {
  const MediaTypeOptionEditorFactory();

  @override
  Widget? build({
    required BuildContext context,
    required String viewId,
    required FieldPB field,
    required PopoverMutex popoverMutex,
    required TypeOptionDataCallback onTypeOptionUpdated,
  }) =>
      null;
}
