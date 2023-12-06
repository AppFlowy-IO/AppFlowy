import 'package:appflowy_backend/protobuf/flowy-database2/field_settings_entities.pb.dart';

extension ToggleVisibility on FieldVisibility {
  FieldVisibility toggle() => switch (this) {
        FieldVisibility.AlwaysShown => FieldVisibility.AlwaysHidden,
        FieldVisibility.AlwaysHidden => FieldVisibility.AlwaysShown,
        _ => FieldVisibility.AlwaysHidden,
      };

  bool isVisibleState() => switch (this) {
        FieldVisibility.AlwaysShown => true,
        FieldVisibility.HideWhenEmpty => true,
        FieldVisibility.AlwaysHidden => false,
        _ => false,
      };
}
