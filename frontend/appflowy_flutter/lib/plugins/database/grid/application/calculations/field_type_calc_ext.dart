import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';

extension AvailableCalculations on FieldType {
  List<CalculationType> calculationsForFieldType() {
    final calculationTypes = [
      CalculationType.Count,
    ];

    // These FieldTypes cannot be empty, or might hold secondary
    // data causing them to be seen as not empty when in fact they
    // are empty.
    if (![
      FieldType.URL,
      FieldType.Checkbox,
      FieldType.LastEditedTime,
      FieldType.CreatedTime,
    ].contains(this)) {
      calculationTypes.addAll([
        CalculationType.CountEmpty,
        CalculationType.CountNonEmpty,
      ]);
    }

    switch (this) {
      case FieldType.Number:
        calculationTypes.addAll([
          CalculationType.Sum,
          CalculationType.Average,
          CalculationType.Min,
          CalculationType.Max,
          CalculationType.Median,
        ]);
        break;
      default:
        break;
    }

    return calculationTypes;
  }
}
