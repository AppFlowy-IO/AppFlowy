import 'package:appflowy/plugins/database_view/application/field/field_info.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_settings_entities.pbenum.dart';
import 'sizes.dart';

class GridLayout {
  static double headerWidth(List<FieldInfo> fields) {
    if (fields.isEmpty) return 0;

    final fieldsWidth = fields
        .where(
          (element) =>
              element.visibility != null &&
              element.visibility != FieldVisibility.AlwaysHidden,
        )
        .map((fieldInfo) => fieldInfo.fieldSettings!.width.toDouble())
        .reduce((value, element) => value + element);

    return fieldsWidth +
        GridSize.leadingHeaderPadding +
        GridSize.trailHeaderPadding;
  }
}
